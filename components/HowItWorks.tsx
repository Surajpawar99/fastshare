
import React from 'react';

const HowItWorks: React.FC = () => {
  return (
    <section id="how-it-works" className="relative py-24 px-6 overflow-hidden">
      {/* Background Decorative Element */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[300px] bg-blue-500/5 rounded-full blur-[120px] pointer-events-none" />
      
      <div className="max-w-5xl mx-auto text-center relative z-10">
        <h2 className="text-4xl md:text-6xl font-black text-white mb-4 tracking-tighter uppercase">
          How FastShare Works
        </h2>

        <p className="mt-4 mb-16 text-gray-500 font-medium uppercase tracking-[0.3em] text-xs md:text-sm">
          Simple • Fast • Local • Universal
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 lg:gap-12">

          {/* Sender Card */}
          <div className="rounded-[2rem] border border-white/10 bg-white/5 p-10 text-left transition-all duration-500 ease-out hover:scale-[1.03] hover:border-blue-400 hover:shadow-[0_0_60px_rgba(59,130,246,0.35)] hover:bg-blue-500/10 group cursor-default relative overflow-hidden">
            <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-20 transition-opacity">
               <svg className="w-20 h-20 text-blue-400" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M21 3H3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm0 16H3V5h18v14zM8 15c0-2.8 2.2-5 5-5s5 2.2 5 5-2.2 5-5 5-5-2.2-5-5z"/>
               </svg>
            </div>
            
            <h3 className="text-2xl font-black text-white mb-6 group-hover:text-blue-400 transition-colors tracking-tight">
              Sender (App Required)
            </h3>
            <ul className="space-y-4 text-gray-400">
              <li className="flex items-center gap-3">
                <span className="w-1.5 h-1.5 rounded-full bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.8)]" />
                <span>Open <strong className="text-gray-200">FastShare</strong> on Android or Windows</span>
              </li>
              <li className="flex items-center gap-3">
                <span className="w-1.5 h-1.5 rounded-full bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.8)]" />
                <span>Select any file or folder (no size limits)</span>
              </li>
              <li className="flex items-center gap-3">
                <span className="w-1.5 h-1.5 rounded-full bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.8)]" />
                <span>QR code or temporary link is generated</span>
              </li>
            </ul>
          </div>

          {/* Receiver Card */}
          <div className="rounded-[2rem] border border-white/10 bg-white/5 p-10 text-left transition-all duration-500 ease-out hover:scale-[1.03] hover:border-purple-400 hover:shadow-[0_0_60px_rgba(168,85,247,0.35)] hover:bg-purple-500/10 group cursor-default relative overflow-hidden">
            <div className="absolute top-0 right-0 p-8 opacity-5 group-hover:opacity-20 transition-opacity">
               <svg className="w-20 h-20 text-purple-400" fill="currentColor" viewBox="0 0 24 24">
                  <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z"/>
               </svg>
            </div>

            <h3 className="text-2xl font-black text-white mb-6 group-hover:text-purple-400 transition-colors tracking-tight">
              Receiver (No App Needed)
            </h3>
            <ul className="space-y-4 text-gray-400">
              <li className="flex items-center gap-3">
                <span className="w-1.5 h-1.5 rounded-full bg-purple-500 shadow-[0_0_8px_rgba(168,85,247,0.8)]" />
                <span>Scan the QR code or open the link</span>
              </li>
              <li className="flex items-center gap-3">
                <span className="w-1.5 h-1.5 rounded-full bg-purple-500 shadow-[0_0_8px_rgba(168,85,247,0.8)]" />
                <span>Download files directly in any browser</span>
              </li>
              <li className="flex items-center gap-3">
                <span className="w-1.5 h-1.5 rounded-full bg-purple-500 shadow-[0_0_8px_rgba(168,85,247,0.8)]" />
                <span>Zero installation, works on iOS/PC/Mac</span>
              </li>
            </ul>
          </div>

        </div>
      </div>
    </section>
  );
};

export default HowItWorks;
