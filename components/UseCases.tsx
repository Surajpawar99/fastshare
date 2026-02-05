
import React from 'react';
import { USE_CASES } from '../constants';

const UseCases: React.FC = () => {
  return (
    <section className="py-24 px-6">
      <div className="max-w-6xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-black text-white mb-4 tracking-tighter uppercase">Everywhere You Need</h2>
          <p className="text-gray-500 font-medium uppercase tracking-widest text-sm">FastShare adapts to your lifestyle</p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {USE_CASES.map((useCase) => (
            <div 
              key={useCase.id}
              className="group glass-card p-8 rounded-3xl transition-all duration-500 border border-white/5 hover:border-blue-500/40 hover:bg-white/[0.06] hover:scale-[1.02] hover:shadow-[0_0_40px_rgba(59,130,246,0.15)] cursor-default relative overflow-hidden"
            >
              {/* Ghost icon in background */}
              <div className="absolute -bottom-6 -right-6 text-7xl opacity-[0.03] group-hover:opacity-[0.1] transition-all duration-700 group-hover:rotate-12 group-hover:scale-150 pointer-events-none">
                {useCase.icon}
              </div>
              
              <div className="text-4xl mb-6 group-hover:scale-110 group-hover:-translate-y-1 transition-all duration-500 origin-left inline-block">
                {useCase.icon}
              </div>
              <div className="transform group-hover:-translate-y-1 transition-transform duration-500">
                <h3 className="text-xl font-bold text-white mb-3 tracking-tight group-hover:text-blue-400 transition-colors">
                  {useCase.title}
                </h3>
                <p className="text-gray-500 text-sm leading-relaxed group-hover:text-gray-300 transition-colors duration-500">
                  {useCase.description}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default UseCases;
