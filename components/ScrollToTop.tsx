
import React, { useState, useEffect, useRef } from 'react';
import { gsap } from 'gsap';

const ScrollToTop: React.FC = () => {
  const [isVisible, setIsVisible] = useState(false);
  const buttonRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    const toggleVisibility = () => {
      if (window.pageYOffset > 500) {
        setIsVisible(true);
      } else {
        setIsVisible(false);
      }
    };

    window.addEventListener('scroll', toggleVisibility);
    return () => window.removeEventListener('scroll', toggleVisibility);
  }, []);

  useEffect(() => {
    if (isVisible) {
      gsap.to(buttonRef.current, {
        opacity: 1,
        y: 0,
        scale: 1,
        duration: 0.4,
        ease: 'back.out(1.7)',
        pointerEvents: 'auto'
      });
    } else {
      gsap.to(buttonRef.current, {
        opacity: 0,
        y: 20,
        scale: 0.8,
        duration: 0.3,
        ease: 'power2.in',
        pointerEvents: 'none'
      });
    }
  }, [isVisible]);

  const handleMouseEnter = () => {
    gsap.to(buttonRef.current, {
      scale: 1.15,
      duration: 0.3,
      ease: 'back.out(1.7)'
    });
    // Brief color flash
    gsap.fromTo(buttonRef.current, 
      { filter: 'brightness(1)' }, 
      { filter: 'brightness(1.5)', duration: 0.1, yoyo: true, repeat: 1, ease: 'power2.inOut' }
    );
  };

  const handleMouseLeave = () => {
    gsap.to(buttonRef.current, {
      scale: 1,
      duration: 0.3,
      ease: 'power2.inOut'
    });
  };

  const scrollToTop = () => {
    window.scrollTo({
      top: 0,
      behavior: 'smooth',
    });
  };

  return (
    <button
      ref={buttonRef}
      onClick={scrollToTop}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      style={{ opacity: 0, transform: 'translateY(20px) scale(0.8)' }}
      className="fixed bottom-8 right-8 z-[90] w-12 h-12 md:w-14 md:h-14 rounded-full bg-gradient-to-r from-[#00d2ff] to-[#9d50bb] text-white shadow-[0_0_20px_rgba(0,210,255,0.4)] flex items-center justify-center transition-all active:scale-95 group overflow-hidden"
      aria-label="Scroll to top"
    >
      <div className="absolute inset-0 bg-white/20 translate-y-full group-hover:translate-y-0 transition-transform duration-300" />
      <svg
        className="w-6 h-6 md:w-7 md:h-7 relative z-10"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2.5}
          d="M5 10l7-7m0 0l7 7m-7-7v18"
        />
      </svg>
    </button>
  );
};

export default ScrollToTop;
