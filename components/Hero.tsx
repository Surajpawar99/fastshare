
import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import Button from './Button';
import { SOCIAL_LINKS } from '../constants';

const Hero: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const tl = gsap.timeline();
    tl.fromTo('.hero-text', 
      { opacity: 0, y: 30 }, 
      { opacity: 1, y: 0, duration: 1, stagger: 0.15, ease: 'power4.out' }
    );

    gsap.fromTo('.social-icon-btn',
      { opacity: 0, scale: 0.5 },
      { opacity: 1, scale: 1, duration: 0.8, stagger: 0.1, ease: 'back.out(1.7)', delay: 1 }
    );

    // Enhanced cinematic floating animation
    gsap.to('.hero-blob', {
      x: 'random(-100, 100)',
      y: 'random(-80, 80)',
      scale: 'random(0.8, 1.3)',
      duration: 'random(15, 25)',
      repeat: -1,
      yoyo: true,
      ease: 'sine.inOut',
      stagger: {
        each: 2,
        from: "random"
      }
    });
  }, []);

  const handleDownload = () => {
    window.open("https://bit.ly/fastshare-apk", "_blank", "noopener,noreferrer");
  };

  const handleWindowsDownload = () => {
    window.open("https://drive.google.com/file/d/1ODiAJ-pWYp-gUlsqxhVGVF-BkWxSpa7k/view?usp=sharing", "_blank", "noopener,noreferrer");
  };

  return (
    <section ref={containerRef} className="min-h-[90vh] flex flex-col items-center justify-center px-6 pt-24 text-center relative overflow-hidden">
      {/* Localized Cinematic Background Blobs */}
      <div className="absolute top-1/4 -left-20 w-72 h-72 bg-blue-500/10 rounded-full blur-[100px] hero-blob pointer-events-none" />
      <div className="absolute bottom-1/4 -right-20 w-80 h-80 bg-purple-500/10 rounded-full blur-[120px] hero-blob pointer-events-none" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[60vw] h-[60vw] bg-blue-600/5 rounded-full blur-[150px] hero-blob pointer-events-none" />

      <div className="max-w-4xl mx-auto z-10 relative">
        <h1 className="hero-text text-7xl md:text-9xl font-black mb-1 bg-clip-text text-transparent bg-gradient-to-b from-white via-white to-blue-400/40 tracking-tighter drop-shadow-2xl">
          FastShare
        </h1>
        
        <p className="hero-text text-xl md:text-3xl text-blue-400 font-medium mb-3 uppercase tracking-[0.25em] neon-text-blue">
          No Internet? No Problem.
        </p>

        <p className="hero-text text-lg md:text-2xl text-gray-400 max-w-2xl mx-auto mb-12 leading-relaxed font-light">
          Share files at <span className="text-white font-medium">lightning speed</span>. Offline. Secure. Simple.
        </p>

        <div className="hero-text flex flex-col sm:flex-row gap-4 justify-center items-center mb-12">
          <Button variant="primary" className="px-10" onClick={handleDownload}>
            Download App
          </Button>
          <Button 
            variant="secondary" 
            className="px-8 py-3 !text-xs !md:text-sm border border-white/10" 
            onClick={handleWindowsDownload}
          >
            <svg className="w-5 h-5 mr-1" fill="currentColor" viewBox="0 0 24 24">
              <path d="M0 3.449L9.75 2.1V11.1H0V3.449zm0 8.551h9.75v9L0 19.65V12zm10.75-10.35L24 0v11.1h-13.25V1.65zM24 12v10.35l-13.25-1.5V12H24z"/>
            </svg>
            Download for Windows
          </Button>
        </div>

        {/* Social Presence */}
        <div className="flex justify-center items-center gap-6">
          {SOCIAL_LINKS.map((link, idx) => (
            <div key={link.platform} className="relative group social-icon-btn">
              <a
                href={link.url}
                target="_blank"
                rel="noopener noreferrer"
                className="w-12 h-12 flex items-center justify-center rounded-full bg-gradient-to-br from-blue-600 to-purple-600 p-[1px] shadow-lg shadow-blue-500/20 hover:shadow-blue-500/40 transition-all duration-300 transform hover:scale-110 hover:rotate-6 cursor-pointer"
              >
                <div className="w-full h-full bg-[#0a0a0f] rounded-full flex items-center justify-center text-gray-300 group-hover:text-white transition-colors">
                  {link.icon}
                </div>
              </a>
              {/* Tooltip */}
              <span className="absolute -bottom-10 left-1/2 -translate-x-1/2 px-3 py-1 bg-white/10 backdrop-blur-md text-white text-[10px] uppercase tracking-widest rounded-md opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none border border-white/10 whitespace-nowrap">
                {link.platform}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="absolute bottom-10 left-1/2 -translate-x-1/2 animate-bounce opacity-20 hidden md:block">
        <div className="w-6 h-10 border-2 border-white rounded-full flex justify-center pt-2">
          <div className="w-1 h-2 bg-white rounded-full" />
        </div>
      </div>
    </section>
  );
};

export default Hero;
