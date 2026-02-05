
import React, { useState, useRef, useEffect } from 'react';
import { gsap } from 'gsap';
import Button from './Button';

const WindowsGuide: React.FC = () => {
  const [activeProblem, setActiveProblem] = useState<number | null>(null);
  const sectionRef = useRef<HTMLDivElement>(null);

  const handleDownload = () => {
    window.open("https://drive.google.com/file/d/1ODiAJ-pWYp-gUlsqxhVGVF-BkWxSpa7k/view?usp=sharing", "_blank", "noopener,noreferrer");
  };

  const problems = [
    {
      id: 1,
      q: "Windows blocks the app",
      a: "The app is new and unsigned. Click 'More info' and then 'Run anyway'. This is safe and expected behavior for niche open-source tools."
    },
    {
      id: 2,
      q: "App doesn't open or closes immediately",
      a: "Ensure all required files are in the same folder: fastshare.exe, flutter_windows.dll, permission_handler_windows_plugin.dll, url_launcher_windows_plugin.dll, and the 'data/' folder. Do NOT delete any DLL files."
    },
    {
      id: 3,
      q: "Files not sending or receiving",
      a: "Sender and Receiver must be on the same Wi-Fi network OR the same hotspot. Try temporarily disabling your Windows Firewall to test connectivity."
    },
    {
      id: 4,
      q: "Browser download page not opening",
      a: "Copy the link manually and open it in Chrome or Edge. Ensure the sender app on the PC is still running during the transfer."
    }
  ];

  return (
    <section id="windows-guide" className="py-24 px-6 relative border-t border-white/5 bg-black/40">
      <div className="max-w-5xl mx-auto" ref={sectionRef}>
        
        {/* Section 1: Windows Download */}
        <div className="glass-card rounded-[3rem] p-10 md:p-16 border border-white/10 relative overflow-hidden mb-16 shadow-[0_0_100px_rgba(59,130,246,0.1)]">
          <div className="absolute top-0 right-0 p-8 opacity-10">
             <svg className="w-32 h-32 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M0 3.449L9.75 2.1V11.1H0V3.449zm0 8.551h9.75v9L0 19.65V12zm10.75-10.35L24 0v11.1h-13.25V1.65zM24 12v10.35l-13.25-1.5V12H24z"/>
             </svg>
          </div>
          
          <div className="relative z-10 text-center md:text-left md:flex items-center justify-between gap-12">
            <div className="max-w-lg mb-10 md:mb-0">
              <h2 className="text-4xl md:text-5xl font-black text-white mb-6 tracking-tighter">
                🖥️ FastShare for Windows
              </h2>
              <p className="text-gray-400 text-lg leading-relaxed mb-8">
                Offline file sharing for Windows using local Wi-Fi or hotspot. 
                <span className="text-white font-medium"> No internet. No cloud. No ads.</span>
              </p>
              <div className="flex flex-col items-center md:items-start gap-3">
                <Button variant="primary" onClick={handleDownload} className="px-12 py-5">
                  Download for Windows
                </Button>
                <span className="text-gray-600 text-xs font-mono uppercase tracking-widest">File: fastshare.exe</span>
              </div>
            </div>
            <div className="hidden lg:block w-px h-64 bg-gradient-to-b from-transparent via-white/10 to-transparent" />
            <div className="space-y-4 text-left">
               <div className="flex items-center gap-4 text-gray-400">
                  <div className="w-2 h-2 rounded-full bg-blue-500 shadow-[0_0_8px_#3b82f6]" />
                  <span className="text-sm">Verified Safe</span>
               </div>
               <div className="flex items-center gap-4 text-gray-400">
                  <div className="w-2 h-2 rounded-full bg-blue-500 shadow-[0_0_8px_#3b82f6]" />
                  <span className="text-sm">Built with Flutter</span>
               </div>
               <div className="flex items-center gap-4 text-gray-400">
                  <div className="w-2 h-2 rounded-full bg-blue-500 shadow-[0_0_8px_#3b82f6]" />
                  <span className="text-sm">Local Network Only</span>
               </div>
            </div>
          </div>
        </div>

        {/* Section 2: Installation Guide */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-16">
          <div className="glass-card rounded-3xl p-10 border border-white/10">
            <h3 className="text-2xl font-bold text-white mb-8 flex items-center gap-3">
              <span className="text-blue-400">📥</span> Installation Guide
            </h3>
            <div className="space-y-8">
              <div className="flex gap-6">
                <div className="flex-shrink-0 w-10 h-10 rounded-xl bg-blue-500/20 text-blue-400 flex items-center justify-center font-bold border border-blue-500/20">1</div>
                <div>
                  <h4 className="text-white font-bold mb-1">Download</h4>
                  <p className="text-gray-500 text-sm">Download fastshare.exe and save it to your Desktop or preferred folder.</p>
                </div>
              </div>
              <div className="flex gap-6">
                <div className="flex-shrink-0 w-10 h-10 rounded-xl bg-blue-500/20 text-blue-400 flex items-center justify-center font-bold border border-blue-500/20">2</div>
                <div>
                  <h4 className="text-white font-bold mb-1">First Launch (SmartScreen)</h4>
                  <p className="text-gray-500 text-sm mb-3">If Windows shows "Windows protected your PC", this is normal for new apps.</p>
                  <div className="bg-white/5 rounded-xl p-4 border border-white/5">
                    <p className="text-white text-xs font-medium mb-2 uppercase tracking-widest text-blue-400">The Fix:</p>
                    <ul className="text-xs text-gray-400 space-y-1">
                      <li>• Click <strong className="text-white">"More info"</strong></li>
                      <li>• Click <strong className="text-white">"Run anyway"</strong></li>
                    </ul>
                  </div>
                </div>
              </div>
              <div className="flex gap-6">
                <div className="flex-shrink-0 w-10 h-10 rounded-xl bg-blue-500/20 text-blue-400 flex items-center justify-center font-bold border border-blue-500/20">3</div>
                <div>
                  <h4 className="text-white font-bold mb-1">Permanent Unblock</h4>
                  <p className="text-gray-500 text-sm">Right-click <code className="text-gray-300">fastshare.exe</code> → Properties → Check <strong className="text-white">"Unblock"</strong> → OK. The warning won't appear again.</p>
                </div>
              </div>
            </div>
          </div>

          {/* Section 3: Important Notes */}
          <div className="glass-card rounded-3xl p-10 border border-white/10 flex flex-col">
            <h3 className="text-2xl font-bold text-white mb-8 flex items-center gap-3">
              <span className="text-blue-400">🛡️</span> Security & Notes
            </h3>
            <div className="flex-grow space-y-4">
              <div className="p-4 rounded-2xl bg-white/5 border border-white/5 hover:bg-white/10 transition-colors">
                 <p className="text-white font-medium text-sm mb-1">Local Network Privacy</p>
                 <p className="text-gray-500 text-xs">No cloud upload. Files are sent directly between devices on your local network.</p>
              </div>
              <div className="p-4 rounded-2xl bg-white/5 border border-white/5 hover:bg-white/10 transition-colors">
                 <p className="text-white font-medium text-sm mb-1">No Background Services</p>
                 <p className="text-gray-500 text-xs">The app only runs when you open it. No telemetry or hidden services installed.</p>
              </div>
              <div className="p-4 rounded-2xl bg-white/5 border border-white/5 hover:bg-white/10 transition-colors">
                 <p className="text-white font-medium text-sm mb-1">Safe & Unsigned</p>
                 <p className="text-gray-500 text-xs">Windows warning ≠ virus. We are working on code signing for future releases.</p>
              </div>
            </div>
            <div className="mt-10 p-4 border border-blue-500/20 bg-blue-500/5 rounded-2xl text-center">
               <p className="text-blue-400 text-xs font-bold uppercase tracking-widest">Pro Tip</p>
               <p className="text-gray-400 text-[10px] mt-1 italic">If transfers fail, restart the PC and your router to refresh local IP routes.</p>
            </div>
          </div>
        </div>

        {/* Section 4: Troubleshooting FAQ */}
        <div className="text-center mb-12">
           <h3 className="text-3xl font-black text-white mb-2 uppercase tracking-tighter">Common Problems</h3>
           <p className="text-gray-500 text-sm uppercase tracking-widest">Find quick solutions for desktop issues</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
           {problems.map((prob) => (
             <div 
               key={prob.id}
               className={`glass-card rounded-2xl p-6 border transition-all duration-300 cursor-pointer ${activeProblem === prob.id ? 'border-blue-500/50 bg-blue-500/5' : 'border-white/10 hover:border-white/20'}`}
               onClick={() => setActiveProblem(activeProblem === prob.id ? null : prob.id)}
             >
               <div className="flex justify-between items-center gap-4">
                 <h4 className="text-white font-bold text-sm">{prob.q}</h4>
                 <div className={`text-blue-400 transition-transform ${activeProblem === prob.id ? 'rotate-180' : ''}`}>
                   <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M19 9l-7 7-7-7" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
                 </div>
               </div>
               {activeProblem === prob.id && (
                 <p className="mt-4 text-gray-400 text-sm leading-relaxed border-t border-white/5 pt-4">
                   {prob.a}
                 </p>
               )}
             </div>
           ))}
        </div>
      </div>
    </section>
  );
};

export default WindowsGuide;
