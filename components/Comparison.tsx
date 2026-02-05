
import React from 'react';
import { COMPARISON_DATA } from '../constants';

const Comparison: React.FC = () => {
  return (
    <section className="py-24 px-6 bg-black/20">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-4xl font-bold text-white mb-4">The Better Choice</h2>
          <p className="text-gray-400">Why settle for legacy tools?</p>
        </div>

        <div className="overflow-x-auto glass-card rounded-3xl border border-white/10">
          <table className="w-full text-left">
            <thead>
              <tr className="border-b border-white/10">
                <th className="py-6 px-8 text-gray-400 font-medium">Feature</th>
                <th className="py-6 px-8 text-white font-bold bg-blue-500/10">FastShare</th>
                <th className="py-6 px-8 text-gray-400 font-medium">Traditional Apps</th>
              </tr>
            </thead>
            <tbody>
              {COMPARISON_DATA.map((row, i) => (
                <tr key={i} className="border-b border-white/5 hover:bg-white/5 transition-colors group">
                  <td className="py-6 px-8 text-gray-400 group-hover:text-white transition-colors">{row.feature}</td>
                  <td className="py-6 px-8 text-white font-semibold bg-blue-500/5">
                    {row.feature === 'Receiver needs app' ? (
                       <span className="px-3 py-1 bg-red-500/20 text-red-400 rounded-full text-xs animate-pulse">NO APP REQUIRED</span>
                    ) : row.fastShare}
                  </td>
                  <td className="py-6 px-8 text-gray-500 italic">{row.others}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
};

export default Comparison;
