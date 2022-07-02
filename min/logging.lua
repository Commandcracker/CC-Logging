local function e(t,a)if type(t)~="table"then return false end if
getmetatable(t)==nil then return false end return getmetatable(t).__index==a
end local function o(i)return type(i)=="table"end local function n(...)local
s=""for h=0,#{...},1 do if h==1 then s="%s"else s=s.." ".."%s"end end return
string.format(s,...)end local function r(d)if term.getPaletteColor then local
l,u,c=term.getPaletteColor(d)return l*255,u*255,c*255 end local
m={[colors.white]={240,240,240},[colors.orange]={242,178,51},[colors.magenta]={229,127,216},[colors.lightBlue]={153,178,242},[colors.yellow]={222,222,108},[colors.lime]={127,204,25},[colors.pink]={242,178,204},[colors.gray]={76,76,76},[colors.lightGray]={153,153,153},[colors.cyan]={76,153,178},[colors.purple]={178,102,229},[colors.blue]={51,102,204},[colors.brown]={127,102,76},[colors.green]={87,166,78},[colors.red]={204,76,76},[colors.black]={17,17,17}}return
unpack(m[d])end local
f={level=0,textcolor=colors.white,backgroundcolor=colors.black}function
f.new(w,y,p,v)return o(w)and setmetatable(w,{__index=f})or
setmetatable({name=w,level=y,textcolor=p,backgroundcolor=v},{__index=f})end
local b={}function b.new(g,k,q)local j=not e(g,f)and
setmetatable(g,{__index=b})or
setmetatable({level=g,message=k,name=q},{__index=b})j.time=j.time or
os.time(os.date("*t"))j.localtime=j.localtime or
os.time(os.date("!*t"))j.day=j.day or os.day()j.computerid=j.computerid or
os.getComputerID()j.computerlabel=j.computerlabel or
os.getComputerLabel()return j end local
x={fmt="[%(time) %(levelname) %(computerid)] %(message)",datefmt="%H:%M:%S"}function
x.new(z,E)return o(z)and setmetatable(z,{__index=x})or
setmetatable({fmt=z,datefmt=E},{__index=x})end function x:format(T)local
A=self.fmt
A=A:gsub("%%%(name%)",T.name)A=A:gsub("%%%(levelname%)",T.level.name)A=A:gsub("%%%(message%)",T.message)A=A:gsub("%%%(time%)",os.date(self.datefmt,T.time))A=A:gsub("%%%(localtime%)",os.date(self.datefmt,T.localtime))A=A:gsub("%%%(day%)",T.day)A=A:gsub("%%%(computerid%)",T.computerid)A=A:gsub("%%%(thread%)",tostring(coroutine.running()):sub(9))if
T.computerlabel then A=A:gsub("%%%(computerlabel%)",T.computerlabel)else
A=A:gsub("%%%(computerlabel%)","")end return A end local
O={channel=rednet.CHANNEL_BROADCAST,protocol="logging"}function
O.new(I,N,S)return not e(I,x)and setmetatable(I,{__index=O})or
setmetatable({formatter=I,channel=N,protocol=S},{__index=O})end function
O:handle(H)rednet.send(self.channel,H,self.protocol)end local R={}function
R.new(D,L)return not e(D,x)and setmetatable(D,{__index=R})or
setmetatable({formatter=D,websocket=L},{__index=R})end function
R:handle(U)self.websocket.send(self.formatter:format(U))end local C={}function
C.new(M,F)return not e(M,x)and setmetatable(M,{__index=C})or
setmetatable({formatter=M,websocket=F},{__index=C})end function
C:handle(W)W.formatter=self.formatter self.websocket.send(W)end local
Y={}function Y.new(P,V)return not e(P,x)and setmetatable(P,{__index=Y})or
setmetatable({formatter=P,websocket=V},{__index=Y})end function
Y:handle(B)local G,K,Q=r(B.level.textcolor)local
J,X,Z=r(B.level.backgroundcolor)self.websocket.send("\27[38;2;"..G..";"..K..";"..Q.."m".."\27[48;2;"..J..";"..X..";"..Z.."m"..self.formatter:format(B).."\27[39m".."\27[49m")end
local et={}function et.new(tt,at)return not e(tt,x)and
setmetatable(tt,{__index=et})or
setmetatable({formatter=tt,file=at},{__index=et})end function
et:handle(ot)self.file.writeLine(self.formatter:format(ot))end local
it={}function it.new(nt)return setmetatable({formatter=nt},{__index=it})end
function it:handle(st)local ht=term.getTextColor()local
rt=term.getBackgroundColor()term.setTextColor(st.level.textcolor)term.setBackgroundColor(st.level.backgroundcolor)write(self.formatter:format(st))term.setTextColor(ht)term.setBackgroundColor(rt)write("\n")end
local dt={protocol="logging"}function dt.new(lt)return
setmetatable({protocol=lt},{__index=dt})end function dt:receive(ut)local
ct,mt=rednet.receive(self.protocol)local
ft=setmetatable(mt,{__index=b})ft.level=setmetatable(ft.level,{__index=f})ut:handel(ft)end
local wt={level=0,recievers={}}function wt.new(yt,pt,vt)local bt=o(yt)and
setmetatable(yt,{__index=wt})or
setmetatable({name=yt,level=pt,formatter=vt},{__index=wt})bt.formatter=bt.formatter
or x.new()bt.defaultHandler=bt.defaultHandler or
it.new(bt.formatter)bt.handlers=bt.handlers
or{bt.defaultHandler}bt.levels=bt.levels
or{DEBUG=f.new("DEBUG",10,colors.cyan),INFO=f.new("INFO",20,colors.green),WARN=f.new("WARN",30,colors.yellow),ERROR=f.new("ERROR",40,colors.red),CRITICAL=f.new("CRITICAL",50,colors.magenta)}return
bt end function wt:addHandler(gt)table.insert(self.handlers,gt)end function
wt:removeHandler(kt)for qt,jt in pairs(self.handlers)do if jt==kt then
table.remove(self.handlers,qt)end end end function
wt:registerLevel(xt)self.levels[xt.name]=xt end function
wt:removeDefaultHandler()if self.defaultHandler then for zt,Et in
pairs(self.handlers)do if Et==self.defaultHandler then
table.remove(self.handlers,zt)end end self.defaultHandler=nil end end function
wt:handel(Tt)for At=1,#self.handlers,1 do self.handlers[At]:handle(Tt)end end
function wt:log(Ot,...)local It=n(...)local
Nt=b.new(Ot,It,self.name)self:handel(Nt)end function
wt:addReciever(St)table.insert(self.recievers,St)end function
wt:getRecieverCoroutines()local Ht={}for Rt=1,#self.recievers,1 do
table.insert(Ht,coroutine.create(function()while true do
self.recievers[Rt]:receive(self)end end))end return Ht end function
wt:debug(...)self:log(self.levels.DEBUG,...)end function
wt:info(...)self:log(self.levels.INFO,...)end function
wt:warn(...)self:log(self.levels.WARN,...)end function
wt:error(...)self:log(self.levels.ERROR,...)end function
wt:critical(...)self:log(self.levels.CRITICAL,...)end local
Dt=wt.new("root")local Lt={}function Lt.debug(...)Dt:debug(...)end function
Lt.info(...)Dt:info(...)end function Lt.warn(...)Dt:warn(...)end function
Lt.error(...)Dt:error(...)end function Lt.critical(...)Dt:critical(...)end
function Lt.log(Ut,...)Dt:log(Ut,...)end Lt.levels=Dt.levels Lt.Level=f
Lt.Record=b Lt.Formatter=x Lt.Logger=wt Lt.TerminalHandler=it Lt.FileHandler=et
Lt.WebsocketHandler=R Lt.ColordWebsocketHandler=Y Lt.RawWebsocketHandler=C
Lt.RednetHandler=O Lt.RednetReciever=dt return
Lt