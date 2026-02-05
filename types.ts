import React from 'react';

export interface Feature {
  id: number;
  icon: string;
  title: string;
  description: string;
}

export interface UseCase {
  id: number;
  title: string;
  description: string;
  icon: string;
}

export interface SocialLink {
  platform: string;
  url: string;
  // Fix: Use React.ReactNode instead of JSX.Element to resolve 'Cannot find namespace JSX' error in .ts files
  icon: React.ReactNode;
}
