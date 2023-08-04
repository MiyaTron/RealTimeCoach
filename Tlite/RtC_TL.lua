--[[
Rialtime Coach LUA script for Jumper T-Lite
(c) MiyaTron
overview:  https://youtu.be/vlGcF2CfoDo
TXmodule and Receiver settings: https://youtu.be/crpQVROY5EM
Install and operation :   https://youtu.be/BlkOteODjc8
]]
local Ver_ = "V1.20230804"
local refreshTime_ = 0
local fieldName_ = {}
local lat_Pilot_ = 35.0000
local lon_Pilot_ = 139.0000
local lat_Center_ = 35.0001
local lon_Center_ = 139.0000
local FFn_ = 1
local FFm_ = 1
fieldName_[FFn_] = "fieldName"
local baseDistance_	= 160.0
local deadband_  = 10.0
local guideStep_  = 5.0
local guidanceY_ = 1
local guidanceA_ = 1
local Apc_  = 0.0
local Lpc_  = 0.0
local Lxpv_ = 0.0
local Lypv_ = 140.0
local Lypvprev_ = Lypv_
local datetime_ = ""
local lat_ = 0.0
local lon_ = 0.0
local sats_ = 0
local satLoss = true
local alt_ = 0
local altprev_ = 0
local pitch_ = 0.0
local Yp_ = (LCD_H ) * 0.90
local posK_  = (baseDistance_/0.8) / (Yp_ * 0.55)
local cnt_blink_ = 0
local cnt_blinkMax_ = 12
local Pi_ = math.pi
local altBias_ = 0
local cnt_keyR_ = 0
local cnt_MDLR_ = 0
local sTime_ = 0
local vTime_ = 0
local page_ = 1
local itemP3_ = 1
local editP3_ = false
local itemP4_ = 1
local editP4_ = false
local logtbl_ = {}
local logmax_ = 0
local logi_ = 0
local ch1flg_ = false
local ch2flg_ = false
local ch4flg_ = false
local ENT_ = false
local RTN_ = false
local UP_ = false
local DN_ = false
local MDL_ = false
local MDLR_ = false
local SYS_ = false
local SYSR_ = false
local positionX_ = {}
local positionY_ = {}
local pn_ = 10
local path_ = "/WIDGETS/RTCoach/RtC/"
local Yb_ = 32
local Xc_ = 8
local Yc_ = 16
local g_fo_ = nil
local g_row_ = 0
local logWfn_ = ""
local logRfn_ = ""
local logRfx_ = ""
local errTone_ = 60
local exeTone_ = 600
if LCD_W < 480 then
path_ = "/SCRIPTS/TELEMETRY/RtC/"
Yb_ = 0
Xc_ = 5
Yc_ = 8
pn_ = 10
else
local page0_img
local pointer0_img
local pointer1_img
local pointer2_img
end
for i_ = 1 , pn_  do
positionX_[i_] = -9
positionY_[i_] = -9
end
local function dateTime()
local year_ = string.format("%04.f", getDateTime()["year"])
local mon_ = string.format("%02.f", getDateTime()["mon"])
local day_ = string.format("%02.f", getDateTime()["day"])
local hour_ = string.format("%02.f", getDateTime()["hour"])
local min_ = string.format("%02.f", getDateTime()["min"])
local sec_ = string.format("%02.f", getDateTime()["sec"])
local dateTime_ = year_ .. "_" .. mon_ .. day_ .. "_"
.. hour_ .. min_ .. sec_
return dateTime_
end
local function getFieldId(fieldname)
field = getFieldInfo(fieldname)
if field then
return field.id
else
return -1
end
end
local function rnd(v,d)
if d then
return math.floor((v*10^d)+0.5)/(10^d)
else
return math.floor(v+0.5)
end
end
local function HubenyDist(lat0_,lon0_,lat1_,lon1_)
local Pi_ = math.pi
local eR_ = 6378137
local e2_ = 6.69437999019758E-03
local W_ = math.sqrt(1 - e2_ * math.sin(((lat0_ + lat1_) / 2)* Pi_ / 180) ^ 2)
local M_ = eR_ * (1 - e2_) / W_ ^ 3
local N_ = eR_ / W_
local distance_ = math.sqrt(((lat1_ - lat0_) * Pi_ / 180 * M_) ^ 2
+ ((lon1_ - lon0_) * Pi_ / 180 * N_ * math.cos(((lat0_ + lat1_) / 2) * Pi_ / 180)) ^2)
return distance_
end
local function azimuthDistance(lat0_, lon0_, lat1_, lon1_)
local distL_ = 	HubenyDist(lat0_,lon0_,lat1_,lon1_)
local distLx_ = HubenyDist(lat0_,lon0_,lat0_,lon1_)
local azimuth_ = math.asin(distLx_/distL_)
if (lat0_ >  lat1_) and (lon0_ <= lon1_) then
azimuth_ = math.pi - azimuth_
elseif (lat0_ > lat1_) and (lon0_ > lon1_) then
azimuth_ = math.pi + azimuth_
elseif (lat0_ <= lat1_) and (lon0_ > lon1_) then
azimuth_ = 2 * math.pi - azimuth_
end
return azimuth_	,distL_
end
local function get_data()
local fieldId_ = -1
fieldId_ = getFieldId("GPS")
if fieldId_ ~= -1 then
local latlon_ = getValue(fieldId_)
if (type(latlon_) == "table") then
lat_ = rnd(latlon_["lat"],6)
lon_ = rnd(latlon_["lon"],6)
end
end
fieldId_ = getFieldId("Sats")
if fieldId_ ~= -1 then
sats_ = getValue(fieldId_)
end
fieldId_ = getFieldId("Alt")
if fieldId_ ~= -1 then
alt_ = getValue(fieldId_)
end
fieldId_ = getFieldId("Ptch")
if fieldId_ ~= -1 then
pitch_ = getValue(fieldId_)
end
end
local function get_key_Tlite(event)
if event ~= nil then
if event == 34 then
UP_ = true
elseif event == 35 then
DN_ = true
elseif event == 33 then
ENT_ = true
elseif event == 32 then
RTN_ = true
elseif event == 36 then
if MDLR_ == false then
MDL_ = true
end
MDLR_ = false
cnt_keyR_ = 0
elseif event == 68 then
MDLR_ = true
elseif event == 37 then
if SYSR_ == false then
SYS_ = true
end
SYSR_ = false
cnt_keyR_ = 0
elseif event == 69 then
SYSR_ = true
end
end
end
local function drowLine1()
local Yf_ = Yp_ - (LCD_W/2)/math.sqrt(3)
Y_ = Yp_ - baseDistance_/posK_
if LCD_W >= 480 then
lcd.drawFilledRectangle(0,(Y_- deadband_/posK_) + 1 ,LCD_W, (deadband_/posK_*2) +1, YELLOW)
end
lcd.drawLine(LCD_W/2,Yp_,LCD_W/2,Yf_, SOLID, FORCE)
lcd.drawLine(LCD_W/2,Yp_,0,Yf_, SOLID, FORCE)
lcd.drawLine(LCD_W/2,Yp_,LCD_W,Yf_, SOLID, FORCE)
lcd.drawLine(0,Y_,LCD_W,Y_, SOLID, FORCE)
end
local function drowData_Lite()
local X_ = 1
local Y_ = 1
lcd.drawText(X_,Y_,fieldName_[FFn_] , SMLSIZE ,BRACK)
X_ = X_ + Xc_ * 11
lcd.drawText(X_,Y_,"S=" .. tostring(sats_) , SMLSIZE ,BRACK)
X_ = 1
Y_ = Yc_
lcd.drawText(X_ ,Y_,"P=" .. tostring(rnd(pitch_*180/Pi_,0)).. " deg" , SMLSIZE ,BRACK)
X_ = X_ + Xc_ * 9
lcd.drawText(X_,Y_,"A=" .. tostring(rnd(alt_ -  altBias_,0)) .. " m" , SMLSIZE ,BRACK)
X_ = LCD_W - Xc_ * 9
Y_ = 1
lcd.drawText(X_ + Xc_,Y_,tostring(rnd(lat_,5)) , SMLSIZE ,BRACK)
lcd.drawText(X_,Y_ + Yc_,tostring(rnd(lon_,5)) , SMLSIZE ,BRACK)
X_ = X_ + Xc_ * 14
if sats_ >= 6 then
lcd.drawText(X_,Y_ + Yc_,"Alt = " .. tostring(rnd(alt_ -  altBias_),0) .. " m" , SMLSIZE ,BRACK)
X_ = 1
Y_ = LCD_H - Yc_ + 2
lcd.drawText(X_,Y_,"X= " .. tostring(rnd(Lxpv_,1)).. " m" , SMLSIZE ,BRACK)
X_ = LCD_W - Xc_ * 9
lcd.drawText(X_,Y_,"Y= " .. tostring(rnd(Lypv_,1)).. " m" , SMLSIZE ,BRACK)
else
lcd.drawText(X_,Y_ + Yc_,"Alt = ??? m", SMLSIZE ,BRACK)
X_ = 1
Y_ = LCD_H - Yc_ + 2
lcd.drawText(X_,Y_,"X= ??? m" , SMLSIZE ,BRACK)
X_ = LCD_W - Xc_ * 9
lcd.drawText(X_,Y_ ,"Y= ??? m" , SMLSIZE ,BRACK)
end
end
local function drowPosition1(Lx_,Ly_)
local imgbias_ = 2
if LCD_W >= 480 then imgbias_ = 8 end
local X_ = LCD_W /2 + Lx_/posK_
local Y_ = Yp_ - Ly_/posK_
local i_ = 1
for i_ = pn_ , 1 , -1 do
if positionX_[i_] ~= nil and positionX_[i_-1] ~= nil and positionY_[i_] ~= nil and positionY_[i_-1] ~= nil then
if (positionX_[i_] > 0 and positionX_[i_] < LCD_W ) and
(positionX_[i_-1] > 0 and positionX_[i_-1] < LCD_W ) and
(positionY_[i_] > Yb_ and positionY_[i_] < LCD_H ) and
(positionY_[i_-1] > Yb_  and positionY_[i_-1] < LCD_H ) then
if LCD_W < 480  then
lcd.drawLine(positionX_[i_],positionY_[i_],positionX_[i_-1],positionY_[i_-1], SOLID, FORCE)
else
lcd.drawLine(positionX_[i_],positionY_[i_],positionX_[i_-1],positionY_[i_-1], SOLID, BLUE)
end
end
end
end
if math.abs(Lx_/posK_) < (LCD_W /2 - 4) then
if cnt_blink_ <= cnt_blinkMax_/2 then
if LCD_W < 480 then
lcd.drawPixmap(X_-2,Y_-2, path_ .. "image/pointer0.bmp")
else
lcd.drawBitmap(pointer0_img, X_-8,Y_-8  , 100)
end
else
if LCD_W < 480 then
lcd.drawPixmap(X_-2,Y_-2, path_ .. "image/pointer1.bmp")
else
lcd.drawBitmap(pointer1_img, X_-8,Y_-8 , 100)
if positionX_[1] > 0 then
lcd.drawLine(positionX_[1],positionY_[1],X_,Y_, SOLID, BLUE)
end
end
end
end
cnt_blink_ = cnt_blink_ + 1
if cnt_blink_ >= cnt_blinkMax_ then
cnt_blink_ = 0
for i_ = pn_ , 2 , -1 do
positionX_[i_] = positionX_[i_-1]
positionY_[i_] = positionY_[i_-1]
end
positionX_[1] = X_
positionY_[1] = Y_
end
end
local function drowLine3()
local posK3_ = posK_ * 1.3
local Y_ = 0 + Yb_
if LCD_W >= 480 then fb_ = -4 end
local F_ = (baseDistance_* math.sqrt(3))/posK3_
lcd.drawLine(0,Yp_,LCD_W,Yp_, SOLID, FORCE)
lcd.drawLine(LCD_W/2 ,Yp_,LCD_W/2 ,Yp_ - F_, SOLID, FORCE)
lcd.drawLine(LCD_W/2 - F_ ,Yp_,LCD_W/2 - F_,Yp_ - F_, SOLID, FORCE)
lcd.drawLine(LCD_W/2 + F_ ,Yp_,LCD_W/2 + F_,Yp_ - F_, SOLID, FORCE)
lcd.drawLine(LCD_W/2 - F_ ,Yp_ - F_,LCD_W/2 + F_,Yp_ - F_, SOLID, FORCE)
end
local function distcall()
if 50 <= rnd(Lypv_,0) and rnd(Lypv_,0) <=200 then
playFile(path_ .. "sound/I" .. string.format("%03d" ,rnd(Lypv_,0) ) .. ".wav")
vTime_ = vTime_ + 50
end
end
local function hightcall()
if 50 <= rnd(Lypv_,0) and rnd(Lypv_,0) <=200 and 10 <= alt_ - altBias_ and alt_ - altBias_ <=300 then
playFile(path_ .. "sound/F" .. string.format("%03d" ,alt_ - altBias_ ) .. ".wav")
vTime_ = vTime_ + 50
end
end
local function distanceGuidance()
local alm_ = false
if (Lypv_ >= 50 and Lypv_ <= 300) then
if (Lypv_ > baseDistance_ + deadband_ + guideStep_ * 3) then
alm_ = true
playFile(path_ .. "sound/FAR4.wav")
vTime_ = vTime_ + 50
elseif	(Lypv_ > baseDistance_ + deadband_ + guideStep_ * 2) then
alm_ = true
playFile(path_ .. "sound/FAR3.wav")
vTime_ = vTime_ + 50
elseif	(Lypv_ > baseDistance_ + deadband_ + guideStep_ * 1) then
alm_ = true
playFile(path_ .. "sound/FAR2.wav")
vTime_ = vTime_ + 50
elseif	(Lypv_ > baseDistance_ + deadband_) then
alm_ = true
playFile(path_ .. "sound/FAR1.wav")
vTime_ = vTime_ + 50
Lypvprev_ = Lypv_
elseif	(Lypv_ > baseDistance_) and Lypv_ > Lypvprev_ + 1 then
alm_ = true
Lypvprev_ = Lypv_
playFile(path_ .. "sound/FAR0.wav")
vTime_ = vTime_ + 50
end
if (Lypv_ < baseDistance_ - deadband_ - guideStep_ * 3) then
alm_ = true
playFile(path_ .. "sound/NEAR4.wav")
vTime_ = vTime_ + 50
elseif (Lypv_ < baseDistance_ - deadband_ - guideStep_ * 2) then
alm_ = true
playFile(path_ .. "sound/NEAR3.wav")
vTime_ = vTime_ + 50
elseif (Lypv_ < baseDistance_ - deadband_ - guideStep_ * 1) then
alm_ = true
playFile(path_ .. "sound/NEAR2.wav")
vTime_ = vTime_ + 50
elseif (Lypv_ < baseDistance_ - deadband_) then
alm_ = true
playFile(path_ .. "sound/NEAR1.wav")
vTime_ = vTime_ + 50
elseif Lypv_ < baseDistance_ and Lypv_ < Lypvprev_ - 1 then
alm_ = true
playFile(path_ .. "sound/NEAR0.wav")
vTime_ = vTime_ + 50
end
if alm_ ==  false then
playFile(path_ .. "sound/good.wav")
vTime_ = vTime_ + 50
else
Lypvprev_ = Lypv_
end
end
return alm_
end
local function hightGuidance()
local alm_ = false
if alt_ > altprev_ + 1 then
alm_ = true
playFile(path_ .. "sound/Hup.wav")
vTime_ = vTime_ + 50
altprev_ = alt_
elseif alt_ < altprev_ - 1 then
alm_ = true
playFile(path_ .. "sound/Hdown.wav")
vTime_ = vTime_ + 50
altprev_ = alt_
end
return alm_
end
local function csvTableRead(fileName_,delim_)
local fo_ = io.open(fileName_, "r")
local tbl_ = {}
local i_ = 1
local j_ = 1
local k_ = 0
local cha_ = ""
local celldata_ = ""
local LfFlg_ = false
tbl_[i_] = {}
tbl_[i_][j_] = ""
if fo_ ~= nil then
while k_ < 500  do
k_ = k_ + 1
cha_ = io.read(fo_,1)
if cha_ == "" then
if celldata_ ~= "" then
tbl_[i_][j_] = celldata_
end
break
elseif LfFlg_ == true then
i_ = i_ + 1
j_ = 1
tbl_[i_] = {}
tbl_[i_][j_] = ""
celldata_ = ""
LfFlg_ = false
end
if cha_ ~= "\r"  and cha_ ~= "\n" and cha_ ~= "\t" and cha_ ~= "\b" and cha_ ~= delim_ and cha_ ~= " " and cha_ ~= nil then
celldata_ = celldata_ .. cha_
end
if cha_ == delim_ then
tbl_[i_][j_] = celldata_
j_ = j_ + 1
celldata_ = ""
end
if cha_ == "\n" then
LfFlg_ = true
tbl_[i_][j_] = celldata_
end
end
io.close(fo_)
end
return tbl_, i_ , j_
end
local function fieldcsvSet()
local i_ = 0
local j_ = 0
local tbl_ = {}
tbl_, i_ , j_ = csvTableRead(path_ .. "field.csv",",")
FFm_ = i_ - 1
for k_ = 2, i_ do
fieldName_[k_-1] = tbl_[k_][1]
end
fieldName_[FFn_] = tbl_[FFn_ +1 ][1]
lat_Pilot_ = tonumber(tbl_[FFn_  +1][2])
lon_Pilot_ = tonumber(tbl_[FFn_  +1][3])
lat_Center_ = tonumber(tbl_[FFn_ +1][4])
lon_Center_ = tonumber(tbl_[FFn_ +1][5])
end
local function  rtcIniWrite()
local fo_ = io.open(path_ .. "Rtc.txt", "w")
io.write(fo_, "FFn_=" .. tostring(FFn_), "\r\n")
io.write(fo_, "baseDistance_=" .. tostring(baseDistance_), "\r\n")
io.write(fo_, "deadband_=" .. tostring(deadband_), "\r\n")
io.write(fo_, "guideStep_=" .. tostring(guideStep_), "\r\n")
io.write(fo_, "guidanceY_=" .. tostring(guidanceY_), "\r\n")
io.write(fo_, "guidanceA_=" .. tostring(guidanceA_), "\r\n")
io.close(fo_)
end
local function page0()
local X_ = 0
local Y_ = 0
lcd.clear()
if LCD_W < 480 then
X_ = LCD_W /2 - Xc_*1.5* #("Real Time Coach")/2
Y_ = LCD_H /2 - Yc_*1.5
lcd.drawText(X_,Y_,"Real Time Coach", MIDSIZE + INVERS )
X_ = 1
Y_ = LCD_H - Yc_ - 5
lcd.drawText(X_,Y_,"(c) MiyaTron")
X_ = LCD_W - Xc_*(#(Ver_)+0)
else
lcd.drawBitmap(page0_img, 0, 0, 100)
X_ = LCD_W - Xc_*(#(Ver_)+2)
Y_ = LCD_H - Yc_ - 5
end
lcd.drawText(X_,Y_,Ver_)
end
local function page12()
local almD_ = false
local almH_ = false
Apc_,Lpc_ = azimuthDistance(lat_Pilot_,lon_Pilot_,lat_Center_,lon_Center_)
local A_,L_ = azimuthDistance(lat_Pilot_,lon_Pilot_,lat_,lon_)
Lxpv_ = L_ * math.sin(A_ - Apc_)
Lypv_ = L_ * math.cos(A_ - Apc_)
if UP_ == true then
UP_ = false
for i_ = 1 , pn_  do
positionX_[i_] = -9
positionY_[i_] = -9
end
end
if DN_ == true then
DN_ = false
for i_ = 1 , #positionX_  do
positionX_[i_] = -9
positionY_[i_] = -9
end
end
if page_ == 1 then
drowLine1()
if LCD_W < 480 then
drowData_Lite()
else
drowData_T16()
end
drowPosition1(Lxpv_,Lypv_)
else
drowLine3()
if LCD_W < 480 then
drowData_Lite()
else
drowData_T16()
end
drowPosition1(Lxpv_ / 1.3,(alt_ -  altBias_) / 1.3)
end
if sats_ >= 6 then
if satLoss == true and (guidanceY_ > 0 or guidanceA_ > 0) then
playFile(path_ .. "sound/guidStart.wav")
satLoss = false
end
if ( pitch_<= -0.35 or 0.35 <= pitch_ ) then
if  (getTime() >= vTime_ ) and (guidanceA_ == 1 or guidanceA_ == 3) then
vTime_ = getTime() + 100
hightcall()
end
else
if  (getTime() >= vTime_ ) then
vTime_ = getTime() + 100
if (guidanceY_ == 2 or guidanceY_ == 3) then
almD_ = distanceGuidance()
if almD_ == true then
distcall()
vTime_ = vTime_ + 50
end
end
if (guidanceA_ == 2 or guidanceA_ == 3) then
almH_ = hightGuidance()
if almH_ == true then
hightcall()
vTime_ = vTime_ + 50
end
end
if almD_ == false and almH_ == false then
if (guidanceY_ == 1 or guidanceY_ == 3)  then
distcall()
end
if (guidanceA_ == 1 or guidanceA_ == 3) then
hightcall()
end
end
end
end
else
if satLoss == false and (guidanceY_ > 0 or guidanceA_ > 0) then
playFile(path_ .. "sound/guidStop.wav")
vTime_ = vTime_ + 50
satLoss = true
end
end
end
local function page3()
local prevFFn_ = FFn_
lcd.drawText(3,Yc_ * 0,"Real Time Coach Setting")
lcd.drawText(Xc_* 1,Yc_ * 1,"Field Name " .. tostring(FFn_),SMLSIZE)
lcd.drawText(Xc_* 1,Yc_ * 2,"Base Distance [m]",SMLSIZE,BRACK)
lcd.drawText(Xc_* 1,Yc_ * 3,"Deadband [m]", SMLSIZE )
lcd.drawText(Xc_* 1,Yc_ * 4,"Guide Step [m]",SMLSIZE,BRACK)
lcd.drawText(Xc_* 1,Yc_ * 5,"Distance(Y) Guidance",SMLSIZE,BRACK)
lcd.drawText(Xc_* 1,Yc_ * 6,"Altitude Guidance",SMLSIZE,BRACK)
Y_ = LCD_H - Yc_
lcd.drawText(Xc_* 1,Y_,("(c)MiyaTron"),SMLSIZE,BRACK)
if itemP3_ == 1 then
if editP3_ == true then
lcd.drawText(Xc_* 15,Yc_ * 1,fieldName_[FFn_],SMLSIZE + INVERS + BLINK)
if UP_ == true then
UP_ = false
FFn_ = FFn_ + 1
if fieldName_[FFn_]=="END" or fieldName_[FFn_]=="" then FFn_ = FFn_ - 1 end
if FFn_ > FFm_  then
FFn_ = FFm_
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if DN_ == true then
DN_ = false
FFn_ = FFn_ - 1
if FFn_ < 1 then
FFn_ = 1
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if FFn_ ~= prevFFn_ and fieldName_[FFn_]~="END" and fieldName_[FFn_]~="" then
fieldcsvSet()
end
else
lcd.drawText(Xc_* 15,Yc_ * 1,fieldName_[FFn_],SMLSIZE + INVERS)
end
else
lcd.drawText(Xc_* 15,Yc_ * 1,fieldName_[FFn_],SMLSIZE)
end
if itemP3_ == 2 then
if editP3_ == true then
lcd.drawText(Xc_* 20,Yc_ * 2,tostring(baseDistance_),SMLSIZE + INVERS + BLINK)
if UP_ == true then
UP_ = false
baseDistance_ = baseDistance_ + 1
if baseDistance_ > 180 then
baseDistance_ = 180
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if DN_ == true then
DN_ = false
baseDistance_ = baseDistance_ - 1
if baseDistance_ < 80 then
baseDistance_ = 80
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
else
lcd.drawText(Xc_* 20,Yc_ * 2,tostring(baseDistance_),SMLSIZE + INVERS)
end
else
lcd.drawText(Xc_* 20,Yc_ * 2,tostring(baseDistance_),SMLSIZE)
end
if itemP3_ == 3 then
if editP3_ == true then
lcd.drawText(Xc_* 20,Yc_ * 3,tostring(deadband_),SMLSIZE + INVERS + BLINK)
if UP_ == true then
UP_ = false
deadband_ = deadband_ + 1
if deadband_ > 50 then
deadband_ = 50
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if DN_ == true then
DN_ = false
deadband_ = deadband_ - 1
if deadband_ < 0 then
deadband_ = 0
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
else
lcd.drawText(Xc_* 20,Yc_ * 3,tostring(deadband_),SMLSIZE + INVERS)
end
else
lcd.drawText(Xc_* 20,Yc_ * 3,tostring(deadband_),SMLSIZE)
end
if itemP3_ == 4 then
if editP3_ == true then
lcd.drawText(Xc_* 20,Yc_ * 4,tostring(guideStep_),SMLSIZE + INVERS + BLINK)
if UP_ == true then
UP_ = false
guideStep_ = guideStep_ + 1
if guideStep_ > 20 then
guideStep_ = 20
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if DN_ == true then
DN_ = false
guideStep_ = guideStep_ - 1
if deadband_ < 1 then
deadband_ = 1
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
else
lcd.drawText(Xc_* 20,Yc_ * 4,tostring(guideStep_),SMLSIZE + INVERS)
end
else
lcd.drawText(Xc_* 20,Yc_ * 4,tostring(guideStep_),SMLSIZE)
end
if itemP3_ == 5 then
if editP3_ == true then
lcd.drawText(Xc_* 20,Yc_ * 5,tostring(guidanceY_),SMLSIZE + INVERS + BLINK)
if UP_ == true then
UP_ = false
guidanceY_ = guidanceY_ + 1
if guidanceY_ > 3 then
guidanceY_ = 3
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if DN_ == true then
DN_ = false
guidanceY_ = guidanceY_ - 1
if guidanceY_ < 0 then
guidanceY_ = 0
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
else
lcd.drawText(Xc_* 20,Yc_ * 5,tostring(guidanceY_),SMLSIZE + INVERS)
end
else
lcd.drawText(Xc_* 20,Yc_ * 5,tostring(guidanceY_),SMLSIZE)
end
if itemP3_ == 6 then
if editP3_ == true then
lcd.drawText(Xc_* 20,Yc_ * 6,tostring(guidanceA_),SMLSIZE + INVERS + BLINK)
if UP_ == true then
UP_ = false
guidanceA_ = guidanceA_ + 1
if guidanceA_ > 3 then
guidanceA_ = 3
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if DN_ == true then
DN_ = false
guidanceA_ = guidanceA_ - 1
if guidanceA_ < 0 then
guidanceA_ = 0
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
else
lcd.drawText(Xc_* 20,Yc_ * 6,tostring(guidanceA_),SMLSIZE + INVERS)
end
else
lcd.drawText(Xc_* 20,Yc_ * 6,tostring(guidanceA_),SMLSIZE)
end
if itemP3_ == 7 then
if editP3_ == true then
lcd.drawText(Xc_* 20,Yc_ * 7,"SAVE", INVERS + BLINK)
rtcIniWrite()
playTone(exeTone_, 500, 50 , PLAY_NOW)
editP3_ = false
else
lcd.drawText(Xc_* 20,Yc_ * 7,"SAVE", INVERS)
end
else
lcd.drawText(Xc_* 20,Yc_ * 7,"SAVE")
end
if ENT_ == true then
ENT_ = false
if editP3_== false then
editP3_= true
else
editP3_= false
end
end
if RTN_ == true or SYS_ == true then
RTN_ = false
SYS_ = false
editP3_= false
page_ = 1
end
if editP3_ == false then
if DN_ == true then
DN_ = false
itemP3_ = itemP3_ - 1
if itemP3_ < 1 then
itemP3_ = 1
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if UP_ == true then
UP_ = false
itemP3_ = itemP3_ + 1
if itemP3_ > 7 then
itemP3_ = 7
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
end
end
local function init_func()
local i_ = 0
local j_ = 0
local k_ = 0
local tbl_ = {}
tbl_, i_ , j_ = csvTableRead(path_ .. "Rtc.txt","=")
for k_ = 1, i_ do
if tbl_[k_][1] == "FFn_" and tbl_[k_][2] ~= "" then FFn_ = tonumber(tbl_[k_][2]) end
if tbl_[k_][1] == "baseDistance_" and tbl_[k_][2] ~= "" then baseDistance_ = tonumber(tbl_[k_][2]) end
if tbl_[k_][1] == "deadband_" and tbl_[k_][2] ~= "" then deadband_ = tonumber(tbl_[k_][2]) end
if tbl_[k_][1] == "guideStep_" and tbl_[k_][2] ~= "" then guideStep_ = tonumber(tbl_[k_][2]) end
if tbl_[k_][1] == "guidanceY_" and tbl_[k_][2] ~= "" then guidanceY_ = tonumber(tbl_[k_][2]) end
if tbl_[k_][1] == "guidanceA_" and tbl_[k_][2] ~= "" then guidanceA_ = tonumber(tbl_[k_][2]) end
end
fieldcsvSet()
end
local function bg_func()
end
local function run_func(event)
lcd.clear()
if sTime_ == 0 then sTime_ = getTime() + 300 end
if  (getTime() <= sTime_ ) then
page0()
else
local i_ = 0
local j_ = 0
if getTime() >= refreshTime_ + 50 then
refreshTime_ = getTime()
if logRfn_ == "" then
get_data()
if logWfn_ ~= "" then
writeLog(path_ .. "log/" .. logWfn_)
end
else
local tbl_ = {}
tbl_, j_ = csvLineRead(path_ .. "log/" .. logRfn_,",")
if g_row_ ~= 0 then
if tbl_[1] ~= nil then datetime_ = tbl_[1] end
if tbl_[2] ~= nil then sats_ = tonumber(tbl_[2]) end
if tbl_[3] ~= nil then lat_ = tonumber(tbl_[3]) end
if tbl_[4] ~= nil then lon_ = tonumber(tbl_[4]) end
if tbl_[5] ~= nil then alt_ = tonumber(tbl_[5]) end
if tbl_[6] ~= nil then altBias_ = tonumber(tbl_[6]) end
if tbl_[7] ~= nil then pitch_ = tonumber(tbl_[7]) end
else
logRfn_ = ""
end
end
end
if LCD_W >= 480 then
get_key_T16(event)
else
get_key_Tlite(event)
end
posK_  = (baseDistance_/0.8) / (Yp_ * 0.55)
if MDL_ == true then
MDL_ = false
if page_ == 1  then
for i_ = 1 , pn_  do
positionX_[i_] = -9
positionY_[i_] = -9
end
end
page_ = page_ + 1
if LCD_W >=480 then
if page_ > 4 then
page_ = 4
playTone(errTone_, 50, 0 , PLAY_NOW)
end
else
if page_ > 3 then
page_ = 3
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
end
if SYS_ == true then
SYS_ = false
if page_ == 2 or page_ == 3 then
for i_ = 1 , pn_  do
positionX_[i_] = -9
positionY_[i_] = -9
end
end
page_ = page_ - 1
if page_ <  1 then
page_ = 1
playTone(errTone_, 50, 0 , PLAY_NOW)
end
end
if SYSR_ == true then
if logRfn_ == "" then
cnt_keyR_ = cnt_keyR_ + 1
if cnt_keyR_ > 50 then
cnt_keyR_ = -100
SYSR_ = false
if page_ == 2 then
if sats_ >= 6 then
altBias_ = alt_
playTone(exeTone_, 500, 50 , PLAY_NOW)
end
end
end
else
playTone(errTone_, 50, 0 , PLAY_NOW)
if LCD_W >=480 then
lcd.drawText(1 + Xc_ * 36,LCD_H - Yc_ * 2 ,"<<< Log Reading ! >>>" , SMLSIZE + INVERS)
end
end
end
if page_== 1 or page_ == 2 then
editP3_ = false
itemP3_ = 1
page12()
elseif page_ == 3 then
page3()
end
end
end
return { run=run_func, background=bg_func, init=init_func  }
