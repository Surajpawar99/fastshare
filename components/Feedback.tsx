
import React, { useState, useRef, useEffect } from 'react';
import { gsap } from 'gsap';
import Button from './Button';

const Feedback: React.FC = () => {
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle');
  const sectionRef = useRef<HTMLDivElement>(null);
  const formRef = useRef<HTMLFormElement>(null);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setStatus('submitting');

    const form = e.currentTarget;
    const data = new FormData(form);

    try {
      const response = await fetch('https://formspree.io/f/xlglqvgp', {
        method: 'POST',
        body: data,
        headers: {
          'Accept': 'application/json'
        }
      });

      if (response.ok) {
        setStatus('success');
        form.reset();
        gsap.fromTo('.success-msg', { opacity: 0, y: 10 }, { opacity: 1, y: 0, duration: 0.5, ease: 'power2.out' });
      } else {
        setStatus('error');
        setTimeout(() => setStatus('idle'), 3000);
      }
    } catch (error) {
      setStatus('error');
      setTimeout(() => setStatus('idle'), 3000);
    }
  };

  return (
    <section ref={sectionRef} className="py-24 px-6 relative">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-12">
          <h2 className="text-4xl md:text-5xl font-black text-white mb-4 tracking-tighter uppercase">
            Send Feedback
          </h2>
          <p className="text-gray-500 font-medium uppercase tracking-widest text-sm">
            Your feedback helps improve FastShare.
          </p>
        </div>

        <div className="glass-card rounded-[2.5rem] p-8 md:p-12 border border-white/10 relative overflow-hidden shadow-2xl">
          {/* Subtle background glow */}
          <div className="absolute -top-24 -right-24 w-64 h-64 bg-teal-500/10 rounded-full blur-[80px] pointer-events-none" />
          
          {status === 'success' ? (
            <div className="success-msg flex flex-col items-center justify-center py-12 text-center">
              <div className="w-20 h-20 bg-teal-500/20 rounded-full flex items-center justify-center mb-6 border border-teal-500/30">
                <svg className="w-10 h-10 text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <h3 className="text-2xl font-bold text-white mb-2">Thanks!</h3>
              <p className="text-gray-400">Your feedback has been sent.</p>
              <button 
                onClick={() => setStatus('idle')}
                className="mt-8 text-teal-400 hover:text-teal-300 transition-colors uppercase tracking-[0.2em] text-[10px] font-bold"
              >
                Send another message
              </button>
            </div>
          ) : (
            <form ref={formRef} onSubmit={handleSubmit} className="space-y-6 relative z-10">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <label htmlFor="name" className="text-[10px] uppercase tracking-[0.2em] text-gray-500 font-bold ml-1">Name (Optional)</label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    placeholder="John Doe"
                    className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-white placeholder:text-gray-600 focus:outline-none focus:border-teal-500/50 focus:ring-4 focus:ring-teal-500/5 transition-all"
                  />
                </div>
                <div className="space-y-2">
                  <label htmlFor="email" className="text-[10px] uppercase tracking-[0.2em] text-gray-500 font-bold ml-1">Email (Optional)</label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    placeholder="john@example.com"
                    className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-white placeholder:text-gray-600 focus:outline-none focus:border-teal-500/50 focus:ring-4 focus:ring-teal-500/5 transition-all"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label htmlFor="message" className="text-[10px] uppercase tracking-[0.2em] text-gray-500 font-bold ml-1">Feedback Message (Required)</label>
                <textarea
                  id="message"
                  name="message"
                  required
                  rows={4}
                  placeholder="Tell us what you think about FastShare..."
                  className="w-full bg-white/5 border border-white/10 rounded-2xl px-6 py-4 text-white placeholder:text-gray-600 focus:outline-none focus:border-teal-500/50 focus:ring-4 focus:ring-teal-500/5 transition-all resize-none"
                />
              </div>

              <div className="pt-4 flex flex-col items-center">
                <Button 
                  className="w-full md:w-auto px-12 py-5 disabled:opacity-50 disabled:cursor-not-allowed"
                  variant="primary"
                >
                  {status === 'submitting' ? (
                    <div className="flex items-center gap-3">
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Sending...
                    </div>
                  ) : status === 'error' ? 'Failed to send' : 'Send Feedback'}
                </Button>
                {status === 'error' && (
                  <p className="mt-4 text-red-400 text-xs font-medium">Something went wrong. Please try again later.</p>
                )}
              </div>
            </form>
          )}
        </div>
      </div>
    </section>
  );
};

export default Feedback;
