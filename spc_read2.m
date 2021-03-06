function chunk = spc_read2(filename)

%   This is the version 2 of spc_read, to read MIRA 35c scpectra using just
%   a filename.
%   
%   Jairo Valdivia - IGP            Mar, 2017 

fid = fopen(filename,'r','ieee-le');
if fid < 0
% 	Header = [];
    error([filename,' not found']);
% 	return;
end
% tic
disp('processing...')
%----------------------------------------
%                   Header 
jname = char(fread(fid,32,'char')');
jtime = char(fread(fid,32,'char')');
joper = char(fread(fid,64,'char')');
jplace = char(fread(fid,128,'char')');
jdescr = char(fread(fid,256,'char')');

fseek(fid,1024,'bof');

% --------------------------------------------
%               Main chunk
% PPAR
Magic4chan = char(fread(fid,4,'char')');
SizeOfDataBlock = fread(fid,1,'int32');
PPAR =  char(fread(fid,4,'char')');
SizeOfPPAR = fread(fid,1,'int32');

Header = struct(...
    'name',jname,...
    'time',jtime,...
    'oper',joper,...
    'place',jplace,...
    'descr',jdescr,...
    'Magic4chan',Magic4chan,...
    'SizeOfDataBlock',SizeOfDataBlock,...
    'PPAR',PPAR,...
    'SizeOfPPAR',SizeOfPPAR);


% Processing parameters
prf = fread(fid,1,'int32');
pdr = fread(fid,1,'int32');
sft = fread(fid,1,'int32');
avc = fread(fid,1,'int32');
ihp = fread(fid,1,'int32');
chg = fread(fid,1,'int32');
pol = fread(fid,1,'int32');

Process_Param = struct(...
    'prf',prf,...
    'pdr',pdr,...
    'sft',sft,...
    'avc',avc,...
    'ihp',ihp,...
    'chg',chg,...
    'pol',pol);

%Service parameters
att = fread(fid,1,'int32');
tx = fread(fid,1,'int32');
ADCGain0 = fread(fid,1,'single');
ADCGain1 = fread(fid,1,'single');
wnd =  fread(fid,1,'int32');
pos = fread(fid,1,'int32');
add = fread(fid,1,'int32');
len = fread(fid,1,'int32');
cal = fread(fid,1,'int32');
nos = fread(fid,1,'int32');
of0 = fread(fid,1,'int32');
of1 = fread(fid,1,'int32');
swt = fread(fid,1,'int32');
sumpulse = fread(fid,1,'int32');
osc = fread(fid,1,'int32');
tst = fread(fid,1,'int32');
cor = fread(fid,1,'int32');
ofs = fread(fid,1,'int32');
HSBn = fread(fid,1,'int32');
HSBa = fread(fid,1,'int32');
calibrpower_m = fread(fid,1,'single');
calibrsnr_m = fread(fid,1,'single');
calibrpower_s = fread(fid,1,'single');
calibrsnr_s = fread(fid,1,'single');
raw_gate1 = fread(fid,1,'int32');
raw_gate2 = fread(fid,1,'int32');
raw = fread(fid,1,'int32');
prc = fread(fid,1,'int32');

Service_Param = struct(...
    'att',att,...
    'tx',tx, ...
    'ADCGain0',ADCGain0, ...
    'ADCGain1',ADCGain1, ...
    'wnd',wnd, ...
    'pos', pos, ...
    'add', add, ...
    'len', len, ...
    'cal', cal, ...
    'nos', nos, ...
    'of0', of0, ...
    'of1', of1, ...
    'swt', swt, ...
    'sumpulse', sumpulse, ...
    'osc', osc, ...
    'tst', tst, ...
    'cor', cor, ...
    'ofs', ofs, ...
    'HSBn', HSBn, ...
    'HSBa', HSBa, ...
    'calibrpower_m', calibrpower_m, ...
    'calibrsnr_m', calibrsnr_m, ...
    'calibrpower_s', calibrpower_s, ...
    'calibrsnr_s', calibrsnr_s, ...
    'raw_gate1', raw_gate1, ...
    'raw_gate2', raw_gate2, ...
    'raw',raw, ...
    'prc', prc);

% DWELL TIME  
Num_Hei = Service_Param.raw_gate2 - Service_Param.raw_gate1;
Num_Bins = Process_Param.sft;

Co_Spc_Mtr = {zeros(Num_Hei,Num_Bins,1)};
Cx_Spc_Mtr = {zeros(Num_Hei,Num_Bins,1)};
HSDV_co = {NaN(Num_Hei,1)};
HSDV_cx = {NaN(Num_Hei,1)};
COFA_co = {NaN(Num_Hei,1)};
COFA_cx = {NaN(Num_Hei,1)};

dwell = {NaN(1,1)};
UTC = {NaN(1,1)};
RadarConst5 = {NaN(1,1)};
npw1 = {NaN(1,1)};
npw2 = {NaN(1,1)};
cpw1 = {NaN(1,1)};
cpw2 = {NaN(1,1)};

disp('reading dwells...')
nd=1;
while 1 % nd=1:2630%ndwells
    
    SignatureSRVI1 = char(fread(fid,4,'char')'); %MBCR - Magic4Chs
    SizeOfDataBlock1 = fread(fid,1,'int32'); %size of dwell 1? n: +8 ()
    DataBlockTitleSRVI1 =  char(fread(fid,4,'char')'); %SRVI
    SizeOfSRVI1 = fread(fid,1,'int32'); %84 bytes

    if SizeOfDataBlock1 == 148
        fread(fid,140,'int8'); %Reading PPAR data
        SignatureSRVI1 = char(fread(fid,4,'char')'); %MBCR - Magic4Chs
        SizeOfDataBlock1 = fread(fid,1,'int32'); %size of dwell
        DataBlockTitleSRVI1 =  char(fread(fid,4,'char')'); %SRVI
        SizeOfSRVI1 = fread(fid,1,'int32'); %84 bytes
    end
    
    if isempty(SizeOfSRVI1); break, end % Romper bucle al finalizar
    if nd > 1
        Co_Spc_Mtr = cat(3,Co_Spc_Mtr,{zeros(Num_Hei,Num_Bins,1)});
        Cx_Spc_Mtr = cat(3,Cx_Spc_Mtr,{zeros(Num_Hei,Num_Bins,1)});
        HSDV_co = cat(2,HSDV_co,{NaN(Num_Hei,1)});
        HSDV_cx = cat(2,HSDV_cx,{NaN(Num_Hei,1)});
        COFA_co = cat(2,COFA_co,{NaN(Num_Hei,1)});
        COFA_cx = cat(2,COFA_cx,{NaN(Num_Hei,1)});

        dwell = cat(2,dwell,{NaN(1,1)});
        UTC = cat(2,UTC,{NaN(1,1)});
        RadarConst5 = cat(2,RadarConst5,{NaN(1,1)});
        npw1 = cat(2,npw1,{NaN(1,1)});
        npw2 = cat(2,npw2,{NaN(1,1)});
        cpw1 = cat(2,{NaN(1,1)});
        cpw2 = cat(2,{NaN(1,1)});
    end
    
    %SRVINET_tag
     frame_cnt = fread(fid,1,'uint32');%:0ul,$
     time_t = fread(fid,1,'uint32');% : 0ul, $
     tpow = fread(fid,1,'single');%   : 0.,  $
     npw1{nd} = fread(fid,1,'single');%   : 0.,  $
     npw2{nd} = fread(fid,1,'single');%   : 0.,  $
     cpw1{nd} = fread(fid,1,'single');%   : 0.,  $
     cpw2{nd} = fread(fid,1,'single');%   : 0.,  $
     ps_err = fread(fid,1,'uint32');% : 0ul, $
     te_err = fread(fid,1,'uint32');% : 0ul, $
     rc_err = fread(fid,1,'uint32');% : 0ul, $
     grs1 = fread(fid,1,'uint32');%   : 0ul, $
     grs2 = fread(fid,1,'uint32');%   : 0ul, $
     azipos = fread(fid,1,'single');% : 0.,  $
     azivel = fread(fid,1,'single');% : 0.,  $
     elvpos = fread(fid,1,'single');% : 0.,  $
     elvvel = fread(fid,1,'single');% : 0.,  $
     northangle = fread(fid,1,'single');% : 0., $
     microsec = fread(fid,1,'int32');% : 0L,  $
     azisetvel = fread(fid,1,'single');% : 0.,  $
     elvsetpos = fread(fid,1,'single');% : 0.,  $
     RadarConst = fread(fid,1,'single');% : 0.  $
                     
                     
    % raw data
    dwell{nd} = time_t;
    RadarConst5{nd} = RadarConst;

    % IN DWELL 4324 THERE IS A ERROR!
    HSDV= char(fread(fid,4,'char')'); %signature
    SizeHSDV = fread(fid,1,'int32'); %NumRan * 2 Chan * 4bytes
    HSDV_co{1,nd} = fread(fid,Num_Hei,'single');
    HSDV_cx{1,nd} = fread(fid,Num_Hei,'single');
    
%     Co_Spc_Mtr(:,:,nd) = repmat(HSDV_co(:,nd)',[Num_Bins,1]);
%     Cx_Spc_Mtr(:,:,nd) = repmat(HSDV_cx(:,nd)',[Num_Bins,1]);
 
    COFA= char(fread(fid,4,'char')'); %signature
    SizeCOFA = fread(fid,1,'int32'); %NumRan * 2 Chan * 4bytes    
    COFA_co{1,nd} = fread(fid,Num_Hei,'single');
    COFA_cx{1,nd} = fread(fid,Num_Hei,'single');

    ZSPC = char(fread(fid,4,'char')'); %signature
    SizeZSPC = fread(fid,1,'int32');
    
    for irg=1:Num_Hei
        nspc = fread(fid,1,'int16');
        for k = 1:nspc
            binIndex = fread(fid,1,'int16')+1;
            nbins = fread(fid,1,'int16');
            %Co-channel
            jbin = fread(fid,nbins,'uint16')';
            jmax = fread(fid,1,'single');
            Co_Spc_Mtr{1,1,nd}(irg,binIndex:binIndex+nbins-1) = Co_Spc_Mtr{1,1,nd}(irg,binIndex:binIndex+nbins-1)+jbin./65530.*jmax;
            %Cx-channel
            jbin = fread(fid,nbins,'uint16')';
            jmax = fread(fid,1,'single');
            Cx_Spc_Mtr{1,1,nd}(irg,binIndex:binIndex+nbins-1) = Cx_Spc_Mtr{1,1,nd}(irg,binIndex:binIndex+nbins-1)+jbin./65530.*jmax;
        end   
    end


    %[Header,Service_Param,Process_Param,UTC,Co_Spc_Mtr,Cx_Spc_Mtr]
    %disp([num2str(nd),' of ',num2str(ndwells),' - ', num2str(round(nd/ndwells*100)),' %'])
    nd = nd+1;
end
fclose(fid);


    daytime=datenum([1970 01 01 00 00 00]);
    tdouble=double(cell2mat(dwell));
    UTC=tdouble/1440/60+daytime;
    clear daytime tdouble

c = 299792458; xmt = 34.85*10^9; %frecuencia
pulse_width = pdr * 10^-9;
delta_h = 0.5 * c * pulse_width;
nrange = raw_gate2-raw_gate1;
range = NaN(nrange,1);
noinor1 = 713031680; % we can find it in /metek/m36s/local/idl/MBCR.config
noinor2 = 30;
ny_vel = c * Process_Param.prf / (4.0*xmt);
vel = 2*ny_vel*((Process_Param.sft-1:-1:0)-Process_Param.sft/2)/Process_Param.sft;

for i = 1:nrange, range(i) = (i-1+raw_gate1)*delta_h; end

    chunk = struct('Header',Header,'Service_Param',Service_Param,...
        'Process_Param',Process_Param,'Co_Spc_Mtr',cell2mat(Co_Spc_Mtr),...
        'Cx_Spc_Mtr',cell2mat(Cx_Spc_Mtr),'UTC',UTC,'RadarConst5',cell2mat(RadarConst5),...
        'HSDV_co',cell2mat(HSDV_co),'HSDV_cx',cell2mat(HSDV_cx),'COFA_co',cell2mat(COFA_co),...
        'COFA_cx',cell2mat(COFA_cx),'npw1',db2pow(cell2mat(npw1))*noinor1*noinor2,'npw2',...
        db2pow(cell2mat(npw2))*noinor1*noinor2,'range',range,'vel',vel); %'cpw1',cpw1,'cpw2',cpw2

%     toc    
disp([filename,' spectra has been read'])