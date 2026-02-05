
import React, { useState, useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import Modal from './Modal';
import { SOCIAL_LINKS } from '../constants';

const AnimatedFooterButton: React.FC<{ onClick: () => void; children: React.ReactNode }> = ({ onClick, children }) => {
  const btnRef = useRef<HTMLButtonElement>(null);

  const handleMouseEnter = () => {
    gsap.to(btnRef.current, { scale: 1.1, color: '#ffffff', duration: 0.2 });
    gsap.fromTo(btnRef.current, 
      { filter: 'brightness(1)' }, 
      { filter: 'brightness(1.8)', duration: 0.1, yoyo: true, repeat: 1 }
    );
  };

  const handleMouseLeave = () => {
    gsap.to(btnRef.current, { scale: 1, color: '#9ca3af', duration: 0.2 });
  };

  return (
    <button 
      ref={btnRef}
      onClick={onClick} 
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      className="text-gray-400 transition-colors text-xs uppercase tracking-widest font-bold"
    >
      {children}
    </button>
  );
};

const Footer: React.FC = () => {
  const [modalType, setModalType] = useState<'privacy' | 'terms' | 'docs' | null>(null);

  useEffect(() => {
    gsap.from('.branding-reveal', {
      scrollTrigger: {
        trigger: '.footer-main',
        start: 'top 90%',
      },
      opacity: 0,
      y: 20,
      duration: 1,
      ease: 'power3.out'
    });
  }, []);

  const modals = {
    privacy: {
      title: "Privacy Policy",
      content: (
        <ul className="list-disc pl-5 space-y-3">
          <li><span className="text-white font-bold">No data collection:</span> FastShare does not monitor your activity.</li>
          <li><span className="text-white font-bold">No tracking:</span> We do not use any tracking pixels or external analytics.</li>
          <li><span className="text-white font-bold">Local Network:</span> Files never leave your local Wi-Fi or Hotspot network.</li>
          <li><span className="text-white font-bold">Direct Transfer:</span> No middle-man servers are involved in file movement.</li>
        </ul>
      )
    },
    terms: {
      title: "Terms of Use",
      content: (
        <ul className="list-disc pl-5 space-y-3">
          <li><span className="text-white font-bold">As-Is:</span> The application is provided "as-is" without any warranties.</li>
          <li><span className="text-white font-bold">User Responsibility:</span> Users are solely responsible for the content they share.</li>
          <li><span className="text-white font-bold">Misuse:</span> We bear no liability for misuse of the platform.</li>
          <li><span className="text-white font-bold">Open Access:</span> Receiver links expire once the sender app is closed.</li>
        </ul>
      )
    },
    docs: {
      title: "Documentation",
      content: (
        <div className="space-y-6">
          <div>
            <h4 className="text-white font-bold mb-2">How it works</h4>
            <p>FastShare creates a temporary local HTTP server on the sender's device. The receiver connects to this server via Wi-Fi Direct or a shared Hotspot.</p>
          </div>
          <div>
            <h4 className="text-white font-bold mb-2">Sender vs Receiver</h4>
            <p>The Sender acts as the host and requires the Android app. The Receiver acts as the client and can use any modern browser (Chrome, Safari, Firefox).</p>
          </div>
          <div>
            <h4 className="text-white font-bold mb-2">Supported File Types</h4>
            <p>All types are supported: Videos (MP4, MKV), Photos, ZIP, APKs, Folders, and large ISO files.</p>
          </div>
        </div>
      )
    }
  };

  return (
    <footer className="footer-main py-20 px-6 relative border-t border-white/5 bg-black/60 overflow-hidden">
      <div className="max-w-6xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-12 items-center">
        
        {/* Brand Section */}
        <div className="text-center lg:text-left">
          <h3 className="text-2xl font-black text-white mb-3">FastShare</h3>
          <p className="text-gray-500 text-sm max-w-xs mx-auto lg:mx-0 leading-relaxed">
            High-speed, offline-first sharing for everyone. No receiver installation needed.
          </p>
        </div>

        {/* Links & Socials Section */}
        <div className="flex flex-col items-center gap-6">
          <nav className="flex flex-wrap justify-center gap-6">
            <AnimatedFooterButton onClick={() => setModalType('privacy')}>Privacy</AnimatedFooterButton>
            <AnimatedFooterButton onClick={() => setModalType('terms')}>Terms</AnimatedFooterButton>
            <AnimatedFooterButton onClick={() => setModalType('docs')}>Docs</AnimatedFooterButton>
          </nav>
          
          <div className="flex justify-center items-center gap-5">
            {SOCIAL_LINKS.map((link, i) => (
              <a 
                key={link.platform} 
                href={link.url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-gray-500 hover:text-blue-400 transition-colors transform hover:scale-110"
                aria-label={link.platform}
              >
                {link.icon}
              </a>
            ))}
          </div>
        </div>

        {/* Branding & Credit */}
        <div className="branding-reveal text-center lg:text-right flex flex-col items-center lg:items-end">
          <div className="group">
            <h2 className="text-xl md:text-2xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-400 drop-shadow-[0_0_8px_rgba(0,210,255,0.3)] group-hover:drop-shadow-[0_0_12px_rgba(0,210,255,0.5)] transition-all duration-500">
              Built with ⚡ by Suraj
            </h2>
            <p className="text-gray-500 text-[10px] mt-1 uppercase tracking-tighter font-medium group-hover:text-gray-300 transition-colors">
              Android Developer • Creator of FastShare
            </p>
          </div>
          <div className="mt-6 text-[9px] text-gray-700 uppercase tracking-[0.4em] font-black opacity-30">
            © 2025 FASTSHARE PROJECT
          </div>
        </div>
      </div>

      <Modal 
        isOpen={!!modalType} 
        onClose={() => setModalType(null)} 
        title={modalType ? modals[modalType].title : ''}
      >
        {modalType ? modals[modalType].content : null}
      </Modal>
    </footer>
  );
};

export default Footer;
