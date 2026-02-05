
import React, { useEffect, useRef, useState } from 'react';
import { gsap } from 'gsap';

const Navbar: React.FC = () => {
  const logoRef = useRef<HTMLDivElement>(null);
  const [logoError, setLogoError] = useState(false);

  useEffect(() => {
    // Initial reveal animation for the navbar
    gsap.fromTo('.nav-container', 
      { y: -100, opacity: 0 }, 
      { y: 0, opacity: 1, duration: 1, ease: 'power4.out' }
    );
  }, []);

  const handleLogoHover = () => {
    gsap.to(logoRef.current, {
      scale: 1.05,
      filter: 'drop-shadow(0 0 15px rgba(20, 184, 166, 0.5))', // Teal cinematic glow
      duration: 0.3,
      ease: 'power2.out'
    });
  };

  const handleLogoLeave = () => {
    gsap.to(logoRef.current, {
      scale: 1,
      filter: 'drop-shadow(0 0 0px rgba(0, 0, 0, 0))',
      duration: 0.3,
      ease: 'power2.inOut'
    });
  };

  const scrollToTop = () => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  return (
    <nav className="nav-container fixed top-0 left-0 right-0 z-[100] px-6 py-4 pointer-events-none">
      <div className="max-w-7xl mx-auto flex items-center justify-between pointer-events-auto">
        <div 
          ref={logoRef}
          onMouseEnter={handleLogoHover}
          onMouseLeave={handleLogoLeave}
          onClick={scrollToTop}
          className="flex items-center gap-3 cursor-pointer group"
        >
          {/* Brand Logo Container */}
          <div className="h-[42px] w-[42px] flex items-center justify-center relative overflow-hidden rounded-[12px] shadow-lg">
            {!logoError ? (
              <img 
                src="logo.png" 
                alt="FastShare Logo" 
                className="h-full w-full object-cover transition-transform duration-300"
                onError={() => setLogoError(true)}
              />
            ) : (
              // Enhanced Fallback Logo: Matches the Teal Cinematic aesthetic of the uploaded image
              <div className="w-full h-full bg-gradient-to-br from-[#2DD4BF] via-[#134E4A] to-[#042F2E] flex items-center justify-center">
                <svg 
                  className="w-6 h-6 text-white drop-shadow-[0_0_8px_rgba(255,255,255,0.6)]" 
                  fill="currentColor" 
                  viewBox="0 0 24 24"
                >
                  <path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" />
                </svg>
              </div>
            )}
            
            {/* Subtle Overlay Shine */}
            <div className="absolute inset-0 bg-gradient-to-tr from-transparent via-white/10 to-transparent pointer-events-none" />
          </div>
          
          <span className="text-xl md:text-2xl font-black text-white tracking-tighter hidden sm:block group-hover:text-teal-400 transition-colors">
            FastShare
          </span>
        </div>

        {/* Minimalist Tech Indicator */}
        <div className="hidden md:flex items-center gap-6">
           <div className="flex items-center gap-2 px-3 py-1 bg-white/5 rounded-full border border-white/10">
             <div className="h-1.5 w-1.5 rounded-full bg-teal-500 animate-pulse shadow-[0_0_8px_#14b8a6]"></div>
             <span className="text-[9px] uppercase tracking-[0.2em] text-gray-400 font-bold">P2P Network Active</span>
           </div>
           <span className="text-[10px] uppercase tracking-[0.3em] text-gray-500 font-bold hidden lg:block">Premium Offline Sharing</span>
        </div>
      </div>
      
      {/* Subtle bottom gradient line */}
      <div className="absolute bottom-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-white/10 to-transparent"></div>
    </nav>
  );
};

export default Navbar;
