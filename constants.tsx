
import React from 'react';

export const FEATURES = [
  {
    id: 1,
    icon: '⚡',
    title: 'Ultra-Fast Offline Transfer',
    description: 'Uses local Wi-Fi / hotspot. No internet required. Optimized for big files (100GB+).'
  },
  {
    id: 2,
    icon: '📱',
    title: 'App Required ONLY for Sender',
    description: 'Sender installs FastShare. Receiver does NOT need the app. Works on any device with a browser.'
  },
  {
    id: 3,
    icon: '🌐',
    title: 'Browser-Based Download',
    description: 'Scan QR → opens browser. Download directly. No installation, no login.'
  },
  {
    id: 4,
    icon: '🔒',
    title: 'Privacy First',
    description: 'No cloud upload. No servers. Files stay local.'
  },
  {
    id: 5,
    icon: '📂',
    title: 'Large File Support',
    description: 'Videos, folders, APKs, ZIPs. Streaming-based transfer. No memory load, no freeze.'
  },
  {
    id: 6,
    icon: '🕘',
    title: 'Transfer History',
    description: 'Sender history saved. Receiver history saved (successful transfers only). No duplicate entries.'
  },
  {
    id: 7,
    icon: '🎯',
    title: 'Lightweight & Fast',
    description: 'Small app size. Fast app launch. Smooth UI, zero latency.'
  }
];

export const USE_CASES = [
  {
    id: 1,
    icon: '🎬',
    title: 'Offline Movies',
    description: 'Share 4K movies with friends during flights or road trips without data.'
  },
  {
    id: 2,
    icon: '💼',
    title: 'Project Handover',
    description: 'Instantly transfer multi-gigabyte project folders to clients on-site.'
  },
  {
    id: 3,
    icon: '🎮',
    title: 'Gaming Party',
    description: 'Share large game obb files and APKs with your squad in seconds.'
  },
  {
    id: 4,
    icon: '🚀',
    title: 'Infinite Possibilities',
    description: 'Your imagination is the only limit.'
  }
];

export const COMPARISON_DATA = [
  {
    feature: 'Receiver needs app',
    fastShare: 'No',
    others: 'Yes'
  },
  {
    feature: 'Average Speed',
    fastShare: '100 MB/s+',
    others: '5-10 MB/s'
  },
  {
    feature: 'Internet Required',
    fastShare: 'No',
    others: 'Usually Yes'
  },
  {
    feature: 'Cloud Storage',
    fastShare: 'Not Required',
    others: 'Required for links'
  },
  {
    feature: 'Privacy',
    fastShare: '100% Local',
    others: 'Server-mediated'
  }
];

export const APP_INFO = {
  version: 'v2.4.1 Stable',
  size: '15.2 MB',
  requirement: 'Android 8.0+'
};

export const SOCIAL_LINKS = [
  { 
    platform: 'Instagram', 
    url: 'https://www.instagram.com/surajpawar.__?igsh=anh2bG5oMXBrdG9y', 
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z" />
      </svg>
    ) 
  },
  { 
    platform: 'LinkedIn', 
    url: 'https://linkedin.com/in/suraj-pawar-752a013aa', 
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M10.067 21.007h-3.558V9.422h3.558v11.585zM8.289 7.854c-1.139 0-2.066-.922-2.066-2.06s.927-2.06 2.066-2.06 2.065.922 2.065 2.06-.926 2.06-2.065 2.06zM21.027 21.007h-3.558v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.927V9.422h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.019z" />
      </svg>
    ) 
  },
  { 
    platform: 'GitHub', 
    url: 'https://github.com/Surajpawar99', 
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
      </svg>
    ) 
  }
];
