
import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}

const Modal: React.FC<ModalProps> = ({ isOpen, onClose, title, children }) => {
  const overlayRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      gsap.fromTo(overlayRef.current, { opacity: 0 }, { opacity: 1, duration: 0.3 });
      gsap.fromTo(contentRef.current, { scale: 0.9, y: 20 }, { scale: 1, y: 0, duration: 0.4, ease: 'back.out(1.7)' });
    } else {
      document.body.style.overflow = 'auto';
    }
  }, [isOpen]);

  if (!isOpen) return null;

  return (
    <div 
      ref={overlayRef}
      className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm"
      onClick={onClose}
    >
      <div 
        ref={contentRef}
        className="glass-card w-full max-w-2xl rounded-3xl p-8 relative max-h-[80vh] overflow-y-auto"
        onClick={(e) => e.stopPropagation()}
      >
        <button 
          onClick={onClose}
          className="absolute top-6 right-6 text-gray-400 hover:text-white transition-colors"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
        <h3 className="text-2xl font-bold text-white mb-6 pr-10">{title}</h3>
        <div className="text-gray-300 space-y-4 leading-relaxed">
          {children}
        </div>
      </div>
    </div>
  );
};

export default Modal;
