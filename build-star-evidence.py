from pathlib import Path
import subprocess,sys,plistlib,argparse
parser=argparse.ArgumentParser();parser.add_argument("--source-root",type=Path,required=True);options=parser.parse_args()
base=Path(__file__).parent
runner=base/'reaction-tests/run.py'
script=runner.read_text().split('with tempfile.TemporaryDirectory')[0]
for mode,revision in [('before','39139593'),('after',None)]:
 sys.argv=[str(runner),'--source-root',str(options.source_root.resolve())]+(['--revision',revision] if revision else [])
 env={'__file__':str(runner)};exec(compile(script,str(runner),'exec'),env)
 code=env['fixture'].split('var checks = 0')[0]
 ui=r'''
import AppKit
let application = NSApplication.shared
application.setActivationPolicy(.regular)
final class Evidence: NSObject, NSApplicationDelegate {
 var window: NSWindow!
 let status=NSTextField(labelWithString:"Ready: transport has not been called")
 let counter=NSTextField(labelWithString:"Local transport calls: 0")
 let interaction=Interaction(peer:Peer(id:PeerId(value:2),allowsReactions:true))
 let output=Context(peerId:PeerId(value:1))
 var retained:(()->Void)!
 var message:Message!
 func applicationDidFinishLaunching(_ notification:Notification) {
  let peer=interaction.peer!
  message=Message(peers:[peer.id:peer])
  var row:Row?=Row(firstMessage:message,chatInteraction:interaction)
  retained=row!.chipStars(message:message,context:output)
  row!.context.account.pendingUpdateMessageManager.media[message.id]=1
  row=nil
  window=NSWindow(contentRect:NSRect(x:150,y:160,width:740,height:400),styleMask:[.titled,.closable],backing:.buffered,defer:false)
  window.title="Retained star chip — __MODE__"
  window.isReleasedWhenClosed=false
  let view=NSView(frame:NSRect(x:0,y:0,width:740,height:400));view.wantsLayer=true;view.layer?.backgroundColor=NSColor.windowBackgroundColor.cgColor
  window.contentView=view
  func label(_ text:String,_ y:CGFloat,_ size:CGFloat) {let l=NSTextField(labelWithString:text);l.font=NSFont.systemFont(ofSize:size,weight:.medium);l.frame=NSRect(x:28,y:y,width:690,height:32);view.addSubview(l)}
  label("Retained star reaction · __MODE__",342,23)
  label("Row replaced · media replacement active · peer allows reactions",296,15)
  label("Production chip callback and message guard; simulated transport",262,14)
  let button=NSButton(title:"★  Tap retained star",target:self,action:#selector(tap));button.bezelStyle = .rounded;button.frame=NSRect(x:28,y:201,width:250,height:38);view.addSubview(button)
  status.frame=NSRect(x:28,y:155,width:690,height:30);status.font=NSFont.systemFont(ofSize:16,weight:.semibold);view.addSubview(status)
  counter.frame=NSRect(x:28,y:116,width:690,height:30);counter.font=NSFont.monospacedSystemFont(ofSize:17,weight:.regular);view.addSubview(counter)
  label("No Telegram account · no network sends · no Stars spent",66,14)
  let export=NSButton(title:"Export native view",target:self,action:#selector(save));export.bezelStyle = .rounded;export.frame=NSRect(x:28,y:20,width:210,height:32);view.addSubview(export)
  window.center();window.makeKeyAndOrderFront(nil);NSApp.activate(ignoringOtherApps:true)
 }
 @objc func tap() {
  tapChip()
  counter.stringValue="Local transport calls: \(output.reactions.calls)"
  status.stringValue=output.reactions.calls==0 ? "Blocked while media replacement is active" : "Submitted while media replacement is active"
  status.textColor=output.reactions.calls==0 ? .systemGreen : .systemRed
 }
 func tapChip() { tap(message:message,context:output,mode:.full,engine:output.reactions,value:.stars,paidAction:retained) }
 @objc func save() {
  guard let view=window.contentView,let rep=view.bitmapImageRepForCachingDisplay(in:view.bounds) else{return}
  view.cacheDisplay(in:view.bounds,to:rep)
  if let data=rep.representation(using:.png,properties:[:]) { try? data.write(to:URL(fileURLWithPath:"__OUTPUT__")) }
 }
}
let delegate=Evidence();application.delegate=delegate;application.run()
'''.replace('__MODE__',mode.upper()).replace('__OUTPUT__',str(base/f'star-{mode}.png'))
 # Avoid same-name NSObject selector shadowing the source callback helper.
 code=code.replace('func tap(message:', 'func invokeChip(message:')
 ui=ui.replace('tap(message:','invokeChip(message:')
 app=base/f'StarEvidence{mode.title()}.app';(app/'Contents/MacOS').mkdir(parents=True,exist_ok=True)
 source=base/f'star-{mode}.swift';source.write_text(code+ui)
 subprocess.run(['swiftc',str(source),'-o',str(app/'Contents/MacOS/StarEvidence')],check=True)
 (app/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier':f'local.codex.StarEvidence{mode.title()}','CFBundleExecutable':'StarEvidence','CFBundleName':f'Star Evidence {mode.title()}','CFBundlePackageType':'APPL'}))
 print(app,flush=True)
