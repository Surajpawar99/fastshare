
import React, { useRef, useEffect } from 'react';
import { gsap } from 'gsap';

interface ButtonProps {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary';
  onClick?: () => void;
  className?: string;
}

const Button: React.FC<ButtonProps> = ({ children, variant = 'primary', onClick, className = '' }) => {
  const buttonRef = useRef<HTMLButtonElement>(null);
  const rippleRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (variant === 'primary') {
      gsap.to(buttonRef.current, {
        boxShadow: '0 0 20px rgba(0, 210, 255, 0.4)',
        duration: 2,
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut'
      });
    }
  }, [variant]);

  const handleMouseEnter = () => {
    // Scale up
    gsap.to(buttonRef.current, {
      scale: 1.05,
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

  const handleClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    if (onClick) onClick();

    // Ripple effect
    const rect = buttonRef.current?.getBoundingClientRect();
    if (rect && rippleRef.current) {
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      
      gsap.set(rippleRef.current, { x, y, scale: 0, opacity: 0.5 });
      gsap.to(rippleRef.current, {
        scale: 4,
        opacity: 0,
        duration: 0.6,
        ease: 'power2.out'
      });
    }
  };

  const baseStyles = "relative overflow-hidden font-bold py-4 px-8 rounded-full transition-all duration-300 flex items-center justify-center gap-2 uppercase tracking-wider text-sm md:text-base";
  const variants = {
    primary: "bg-gradient-to-r from-[#00d2ff] to-[#9d50bb] text-white",
    secondary: "glass-card text-white hover:bg-white/10"
  };

  return (
    <button
      ref={buttonRef}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onClick={handleClick}
      className={`${baseStyles} ${variants[variant]} ${className}`}
    >
      <div ref={rippleRef} className="absolute w-20 h-20 bg-white/30 rounded-full pointer-events-none transform -translate-x-1/2 -translate-y-1/2" />
      <span className="relative z-10">{children}</span>
    </button>
  );
};

export default Button;
