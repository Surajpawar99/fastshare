
import React from 'react';
import Button from './Button';
import { APP_INFO } from '../constants';

const Download: React.FC = () => {
  const handleDownload = () => {
    window.open("https://bit.ly/fastshare-apk", "_blank", "noopener,noreferrer");
  };

  return (
    <section id="download" className="py-24 px-6 relative overflow-hidden">
      <div className="max-w-4xl mx-auto glass-card rounded-[3rem] p-12 md:p-16 text-center border-t border-white/10 relative">
        
        <div className="inline-flex flex-wrap justify-center gap-3 mb-12">
          <div className="px-4 py-2 bg-blue-500/10 border border-blue-500/20 rounded-full text-blue-400 text-xs font-bold uppercase tracking-widest">
            {APP_INFO.version}
          </div>
          <div className="px-4 py-2 bg-white/5 border border-white/10 rounded-full text-gray-400 text-xs font-bold uppercase tracking-widest">
            {APP_INFO.size}
          </div>
          <div className="px-4 py-2 bg-purple-500/10 border border-purple-500/20 rounded-full text-purple-400 text-xs font-bold uppercase tracking-widest">
            {APP_INFO.requirement}
          </div>
        </div>

        <h2 className="text-4xl md:text-6xl font-black text-white mb-8 tracking-tighter">
          Ready to experience <br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-purple-400">speed?</span>
        </h2>
        
        <div className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-12">
          <Button variant="primary" className="w-full sm:w-auto px-16 py-5" onClick={handleDownload}>
            Download APK
          </Button>

          <div className="p-3 bg-white rounded-2xl hidden md:block group hover:scale-105 transition-transform">
            <a href="https://bit.ly/fastshare-apk" target="_blank" rel="noopener noreferrer">
              <img 
                src="https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=https://bit.ly/fastshare-apk" 
                alt="QR Code" 
                className="w-20 h-20 opacity-90"
              />
            </a>
          </div>
        </div>

        <p className="text-gray-500 text-sm max-w-sm mx-auto uppercase tracking-tighter opacity-50">
          Peer-to-peer sharing enabled. No data tracking.
        </p>
      </div>
    </section>
  );
};

export default Download;
