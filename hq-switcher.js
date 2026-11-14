/* Sovereign Sports shared HQ navigation, version 1.2. Pure UI; never grants director access. */
(()=>{
'use strict';
if(document.getElementById('sovereign-hq-nav')) return;
const flag='sovereign-hq-director-navigation';
const params=new URLSearchParams(location.search);
if(params.get('director')==='0'){sessionStorage.removeItem(flag);return;}
if(params.get('director')==='1')sessionStorage.setItem(flag,'1');
// Hide the control on public/player views, including Registration's public waiver.
if(params.get('waiver')==='universal'||params.has('player')||params.has('public'))return;
if(sessionStorage.getItem(flag)!=='1')return;
const targets=[
 ['Director Hub','Choose an application','https://sovereignsports.github.io/Director-Hub-Test/'],
 ['Registration HQ','Registrations and waivers','https://sovereignsports.github.io/Registration-HQ-Test/?director=1'],
 ['League HQ','Seasons, teams and schedules','https://sovereignsports.github.io/League-HQ/?director=1'],
 ['Tournament HQ','Events, brackets and results','https://christofercaylum.github.io/Tournament-HQ/?director=1']
];
const here=location.hostname+location.pathname.toLowerCase().replace(/\/$/,'');
const css=document.createElement('style');css.textContent=`#sovereign-hq-nav{position:fixed;right:14px;bottom:max(16px,env(safe-area-inset-bottom));z-index:2147483000;font:14px/1.4 system-ui,-apple-system,sans-serif;color:#17314b}#sovereign-hq-nav button{font:inherit;cursor:pointer}#sovereign-hq-nav .shq-toggle{background:#132a4b;color:#fff;border:2px solid #d4ac5c;border-radius:40px;padding:12px 16px;font-weight:750;box-shadow:0 5px 20px #0004}#sovereign-hq-nav .shq-menu{background:#fff;color:#17314b;border:1px solid #ccd7e3;border-radius:15px;padding:10px;margin:0 0 10px auto;width:min(320px,calc(100vw - 26px));max-height:70vh;overflow:auto;box-shadow:0 9px 32px #0004}#sovereign-hq-nav .shq-menu[hidden]{display:none!important}#sovereign-hq-nav a{display:block;padding:12px;color:#17314b;text-decoration:none;border-radius:8px;font-weight:700}#sovereign-hq-nav a span{display:block;font-weight:400;color:#596d80;font-size:12px;margin-top:3px}#sovereign-hq-nav a[aria-current="page"]{background:#eff3f8}#sovereign-hq-nav a:hover,#sovereign-hq-nav a:focus-visible{background:#eaf0f7;outline:2px solid #d4ac5c}#sovereign-hq-nav .shq-heading{font-size:11px;letter-spacing:1px;font-weight:800;padding:5px 12px;color:#52697d}`;
document.head.appendChild(css);
const root=document.createElement('nav');root.id='sovereign-hq-nav';root.setAttribute('aria-label','Navigate between Sovereign Sports headquarters');
const menu=document.createElement('div');menu.className='shq-menu';menu.id='sovereign-hq-menu';menu.hidden=true;
const title=document.createElement('div');title.className='shq-heading';title.textContent='SWITCH HEADQUARTERS';menu.appendChild(title);
for(const [name,desc,url] of targets){const link=document.createElement('a');link.href=url;link.textContent=name;const subtitle=document.createElement('span');subtitle.textContent=desc;link.appendChild(subtitle);const dest=new URL(url);if(dest.hostname+dest.pathname.toLowerCase().replace(/\/$/,'')===here){link.setAttribute('aria-current','page');}menu.appendChild(link);}
const toggle=document.createElement('button');toggle.type='button';toggle.className='shq-toggle';toggle.textContent='⇄ Switch HQ';toggle.setAttribute('aria-controls',menu.id);toggle.setAttribute('aria-expanded','false');
function setOpen(value){menu.hidden=!value;toggle.setAttribute('aria-expanded',String(value));}
toggle.addEventListener('click',()=>setOpen(menu.hidden));document.addEventListener('keydown',e=>{if(e.key==='Escape')setOpen(false);});document.addEventListener('pointerdown',e=>{if(!root.contains(e.target))setOpen(false);});
root.append(menu,toggle);
if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',()=>document.body.appendChild(root),{once:true});else document.body.appendChild(root);
})();
