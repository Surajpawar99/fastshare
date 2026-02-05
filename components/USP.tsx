
import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';

const USP: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const iconRef = useRef<HTMLDivElement>(null);
  const textRef = useRef<HTMLHeadingElement>(null);

  useEffect(() => {
    const tl = gsap.timeline({
      scrollTrigger: {
        trigger: containerRef.current,
        start: 'top 80%',
      }
    });

    tl.from(containerRef.current, {
      scale: 0.9,
      opacity: 0,
      duration: 1,
      ease: 'power3.out'
    })
    .from(iconRef.current, {
      y: -50,
      opacity: 0,
      duration: 0.8,
      ease: 'bounce.out'
    }, "-=0.5")
    .from(textRef.current, {
      opacity: 0,
      scale: 1.1,
      duration: 0.8,
      ease: 'power2.out'
    }, "-=0.3");

    // Border pulse
    gsap.to(containerRef.current, {
      borderColor: 'rgba(157, 80, 187, 0.6)',
      duration: 1.5,
      repeat: -1,
      yoyo: true,
      ease: 'sine.inOut'
    });
  }, []);

  return (
    <section className="py-24 px-6">
      <div 
        ref={containerRef}
        className="max-w-4xl mx-auto glass-card rounded-[2.5rem] p-12 text-center border-2 border-[#00d2ff]/20 shadow-[0_0_50px_rgba(0,210,255,0.1)] relative overflow-hidden"
      >
        <div className="absolute inset-0 bg-gradient-to-r from-blue-500/5 to-purple-500/5" />
        
        <div ref={iconRef} className="text-6xl mb-6 inline-block">
          🚀
        </div>
        
        <h2 
          ref={textRef}
          className="text-3xl md:text-5xl font-extrabold text-white leading-tight uppercase tracking-tighter"
        >
          Receiver needs <span className="text-[#00d2ff] neon-text-blue">NO app</span>.<br />
          Sender only.
        </h2>
        
        <p className="text-gray-400 mt-6 text-lg max-w-xl mx-auto">
          Simply open the browser on the receiving device. No more waiting for friends to install apps.
        </p>

        <div className="mt-8 flex justify-center gap-2">
          {[1, 2, 3].map(i => (
            <div key={i} className="w-2 h-2 rounded-full bg-blue-500/40 animate-pulse" style={{ animationDelay: `${i * 0.2}s` }} />
          ))}
        </div>
      </div>
    </section>
  );
};

export default USP;
