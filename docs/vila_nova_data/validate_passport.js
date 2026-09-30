const fs=require('fs'),path=require('path');
const dir=process.argv[2];const pdir=path.join(dir,'passport');
const venues=JSON.parse(fs.readFileSync(path.join(pdir,'venues.json'),'utf8'));
const vs=venues.venues||Object.values(venues).find(Array.isArray);
const vnames=new Set(vs.flatMap(x=>[x.canonical_name,x.display_name,...(x.aliases||[])]));
const vids=new Set(vs.map(v=>v.id));if(vids.size!==vs.length)console.log('VENUE ID DUPLICADO');
const aud=JSON.parse(fs.readFileSync(path.join(pdir,'passport_audit_manifest.json'),'utf8'));
const rows=aud.years||aud.rows||Object.values(aud).find(Array.isArray);
const allIds=new Map();
for(const f of fs.readdirSync(pdir).filter(f=>/^passport_\d{4}\.json$/.test(f)).sort()){
 const y=+f.match(/\d{4}/)[0];const ms=JSON.parse(fs.readFileSync(path.join(pdir,f),'utf8')).matches;
 const pb=[];const byc={};let est=0;
 for(const m of ms){
  if(allIds.has(m.id))pb.push('id dup com '+allIds.get(m.id)+': '+m.id);allIds.set(m.id,y);
  byc[m.competition_code]=(byc[m.competition_code]||0)+1;
  if(m.status==='FINISHED'){
   const cs=m.club_is_home?m.home_score:m.away_score,os=m.club_is_home?m.away_score:m.home_score;
   if(cs!==m.club_score||os!==m.opponent_score)pb.push(m.id+' club_score');
   const o=cs>os?'WIN':cs<os?'LOSS':'DRAW';if(o!==m.outcome)pb.push(m.id+' outcome '+m.outcome+'≠'+o);
   if(m.score_display!==m.home_score+'–'+m.away_score)pb.push(m.id+' score_display '+m.score_display);
   if((m.penalty_home_score==null)!==(m.penalty_away_score==null))pb.push(m.id+' pen meia');
   if(m.penalty_home_score!=null&&cs!==os)pb.push(m.id+' pen sem empate (agregado?)');
  }
  const vn=m.club_is_home?m.home_team:m.away_team;if(!/vila nova/i.test(vn))pb.push(m.id+' lado: '+vn);
  if(/vila nova/i.test(m.club_is_home?m.away_team:m.home_team))pb.push(m.id+' vila dos dois lados');
  if(m.stadium){est++;if(m.stadium_status!=='MATCH_SPECIFIC')pb.push(m.id+' estadio sem MATCH_SPECIFIC');if(!vnames.has(m.stadium))pb.push(m.id+' estadio fora de venues: '+m.stadium)}
  else if(m.stadium_status==='MATCH_SPECIFIC')pb.push(m.id+' MATCH_SPECIFIC sem estadio');
  if(m.calendar_year!==y||!String(m.date).startsWith(String(y)))pb.push(m.id+' ano '+m.date);
  if(!m.source_url)pb.push(m.id+' sem source_url');
 }
 const dd={};ms.forEach(m=>dd[m.date]=(dd[m.date]||0)+1);Object.entries(dd).filter(([k,v])=>v>1).forEach(([k])=>pb.push('data repetida '+k));
 const r=rows.find(r=>(r.year||r.calendar_year)===y)||{};
 if(r.found_total!==ms.length)pb.push('manifest found_total '+r.found_total+' ≠ '+ms.length);
 if(r.by_competition){for(const k of new Set([...Object.keys(r.by_competition),...Object.keys(byc)]))if(r.by_competition[k]!==byc[k])pb.push('manifest '+k+' '+r.by_competition[k]+'≠'+byc[k])}
 if(r.expected_total!=null&&r.expected_total!==ms.length)pb.push('expected '+r.expected_total+' ≠ '+ms.length);
 const W=ms.filter(m=>m.outcome==='WIN').length,D=ms.filter(m=>m.outcome==='DRAW').length,L=ms.filter(m=>m.outcome==='LOSS').length;
 console.log(y,String(ms.length).padStart(3),'jogos',r.coverage_status,'estadio '+est+'/'+ms.length,'V'+W+' E'+D+' D'+L,JSON.stringify(byc),pb.length?'\n   ⚠ '+pb.join('\n   ⚠ '):'OK');
}
console.log('venues',vs.length,'| total partidas',allIds.size);
