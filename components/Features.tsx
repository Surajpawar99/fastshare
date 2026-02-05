
import React, { useState, useRef, useEffect } from 'react';
import { gsap } from 'gsap';
import { FEATURES } from '../constants';
import Modal from './Modal';

const FeatureCard: React.FC<{ feature: typeof FEATURES[0], onShare: (feature: typeof FEATURES[0]) => void }> = ({ feature, onShare }) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const cardRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const arrowRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (isExpanded) {
      gsap.to(contentRef.current, { height: 'auto', opacity: 1, duration: 0.4, ease: 'power2.out' });
      gsap.to(arrowRef.current, { rotate: 180, duration: 0.3 });
    } else {
      gsap.to(contentRef.current, { height: 0, opacity: 0, duration: 0.3, ease: 'power2.in' });
      gsap.to(arrowRef.current, { rotate: 0, duration: 0.3 });
    }
  }, [isExpanded]);

  const handleMouseEnter = () => {
    gsap.to(cardRef.current, {
      scale: 1.02,
      boxShadow: '0 0 30px rgba(0, 210, 255, 0.15)',
      borderColor: 'rgba(0, 210, 255, 0.3)',
      backgroundColor: 'rgba(255, 255, 255, 0.05)',
      duration: 0.4,
      ease: 'power2.out'
    });
  };

  const handleMouseLeave = () => {
    gsap.to(cardRef.current, {
      scale: 1,
      boxShadow: '0 0 0px rgba(0, 0, 0, 0)',
      borderColor: 'rgba(255, 255, 255, 0.1)',
      backgroundColor: 'rgba(255, 255, 255, 0.03)',
      duration: 0.4,
      ease: 'power2.inOut'
    });
  };

  return (
    <div 
      ref={cardRef}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      className="glass-card rounded-3xl p-6 md:p-8 cursor-pointer group overflow-hidden transition-colors border border-white/10"
      onClick={() => setIsExpanded(!isExpanded)}
    >
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-6">
          <span className="text-4xl group-hover:scale-110 transition-transform duration-300">{feature.icon}</span>
          <h3 className="text-xl md:text-2xl font-bold text-white group-hover:text-blue-400 transition-colors duration-300">
            {feature.title}
          </h3>
        </div>
        <div ref={arrowRef} className="text-gray-500 group-hover:text-blue-400 transition-colors duration-300">
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
          </svg>
        </div>
      </div>
      <div ref={contentRef} className="h-0 opacity-0 overflow-hidden">
        <div className="pt-6 text-gray-400 leading-relaxed text-lg border-t border-white/5 mt-4 flex flex-col gap-6">
          <p>{feature.description}</p>
          <div className="flex justify-end">
            <button 
              onClick={(e) => {
                e.stopPropagation();
                onShare(feature);
              }}
              className="flex items-center gap-2 px-4 py-2 rounded-full bg-blue-500/10 border border-blue-500/20 text-blue-400 text-xs font-bold uppercase tracking-widest hover:bg-blue-500/20 transition-colors"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.684 13.342C8.886 12.938 9 12.482 9 12c0-.482-.114-.938-.316-1.342m0 2.684a3 3 0 110-2.684m0 2.684l6.632 3.316m-6.632-6l6.632-3.316m0 0a3 3 0 105.367-2.684 3 3 0 00-5.367 2.684zm0 9.316a3 3 0 105.368 2.684 3 3 0 00-5.368-2.684z" />
              </svg>
              Share Feature
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

const Features: React.FC = () => {
  const [sharingFeature, setSharingFeature] = useState<typeof FEATURES[0] | null>(null);
  const [copyStatus, setCopyStatus] = useState<string | null>(null);

  const handleCopy = (text: string, label: string) => {
    navigator.clipboard.writeText(text).then(() => {
      setCopyStatus(label);
      setTimeout(() => setCopyStatus(null), 2000);
    });
  };

  const handleShareLink = (feature: typeof FEATURES[0]) => {
    const shareUrl = `${window.location.origin}${window.location.pathname}#feature-${feature.id}`;
    handleCopy(shareUrl, 'Link');
  };

  return (
    <section className="py-24 px-6 relative">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-6xl font-black text-white mb-4 tracking-tighter">Key Features</h2>
          <div className="w-20 h-1 bg-gradient-to-r from-blue-500 to-purple-500 mx-auto rounded-full" />
        </div>

        <div className="flex flex-col gap-4">
          {FEATURES.map((feature) => (
            <FeatureCard key={feature.id} feature={feature} onShare={setSharingFeature} />
          ))}
        </div>
      </div>

      <Modal 
        isOpen={!!sharingFeature} 
        onClose={() => setSharingFeature(null)} 
        title={`Share: ${sharingFeature?.title}`}
      >
        <div className="space-y-6">
          <p className="text-gray-400 text-sm">Spread the word about FastShare's powerful capabilities.</p>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <button 
              onClick={() => sharingFeature && handleCopy(sharingFeature.description, 'Description')}
              className="flex flex-col items-center justify-center gap-3 p-6 rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 hover:border-blue-500/50 transition-all group"
            >
              <div className="w-12 h-12 rounded-full bg-blue-500/10 flex items-center justify-center text-blue-400 group-hover:scale-110 transition-transform">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 5H6a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2v-1M8 5a2 2 0 012-2h2a2 2 0 012 2m0 0h2a2 2 0 012 2v3m2 4H10m0 0l3-3m-3 3l3 3" />
                </svg>
              </div>
              <span className="text-xs font-bold uppercase tracking-widest text-white">Copy Description</span>
              {copyStatus === 'Description' && <span className="text-[10px] text-teal-400 animate-pulse">Copied!</span>}
            </button>

            <button 
              onClick={() => sharingFeature && handleShareLink(sharingFeature)}
              className="flex flex-col items-center justify-center gap-3 p-6 rounded-2xl bg-white/5 border border-white/10 hover:bg-white/10 hover:border-purple-500/50 transition-all group"
            >
              <div className="w-12 h-12 rounded-full bg-purple-500/10 flex items-center justify-center text-purple-400 group-hover:scale-110 transition-transform">
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.826L10.242 9.172a4 4 0 015.656 0l4 4a4 4 0 01-5.656 5.656l-1.102 1.101" />
                </svg>
              </div>
              <span className="text-xs font-bold uppercase tracking-widest text-white">Share Link</span>
              {copyStatus === 'Link' && <span className="text-[10px] text-teal-400 animate-pulse">Link Copied!</span>}
            </button>
          </div>
        </div>
      </Modal>
    </section>
  );
};

export default Features;
