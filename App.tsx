
import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

import Navbar from './components/Navbar';
import Hero from './components/Hero';
import Features from './components/Features';
import HowItWorks from './components/HowItWorks';
import UseCases from './components/UseCases';
import Comparison from './components/Comparison';
import Download from './components/Download';
import WindowsGuide from './components/WindowsGuide';
import Feedback from './components/Feedback';
import Footer from './components/Footer';
import USP from './components/USP';
import ScrollToTop from './components/ScrollToTop';

gsap.registerPlugin(ScrollTrigger);

const App: React.FC = () => {
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const sections = gsap.utils.toArray('section');
    sections.forEach((section: any) => {
      gsap.fromTo(
        section,
        { opacity: 0, y: 30 },
        {
          opacity: 1,
          y: 0,
          duration: 1.2,
          ease: 'power3.out',
          scrollTrigger: {
            trigger: section,
            start: 'top 85%',
            toggleActions: 'play none none none',
          }
        }
      );
    });

    return () => {
      ScrollTrigger.getAll().forEach(t => t.kill());
    };
  }, []);

  return (
    <div ref={containerRef} className="relative w-full overflow-hidden bg-[#0a0a0f] selection:bg-blue-500 selection:text-white">
      {/* Cinematic Background Blobs */}
      <div className="fixed inset-0 pointer-events-none z-0">
        <div className="absolute top-[-10%] left-[-10%] w-[40vw] h-[40vw] bg-blue-600/10 rounded-full blur-[120px] blob" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[50vw] h-[50vw] bg-purple-600/10 rounded-full blur-[150px] blob" />
      </div>

      <Navbar />

      <main className="relative z-10">
        <Hero />
        <USP />
        <Features />
        <HowItWorks />
        <UseCases />
        <Comparison />
        <Download />
        <WindowsGuide />
        <Feedback />
        <Footer />
      </main>

      <ScrollToTop />
    </div>
  );
};

export default App;
