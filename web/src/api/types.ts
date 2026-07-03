/* web/src/api/types.ts */

export interface User {
  id: string;
  email: string;
  verified: boolean;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface MeResponse {
  user: User;
}

export type PostStatus = 'fresh' | 'likely' | 'fading' | 'gone';

export interface Tallies {
  present: number;
  gone: number;
}

export interface Post {
  id: string;
  foodName: string;
  location: string;
  imageKey?: string;
  badges: string[];
  author: string;
  status: PostStatus;
  confidence?: number;
  tallies: Tallies;
  expiresAt: string;
  createdAt: string;
}

export interface MessageResponse {
  message: string;
}

export interface ChangePasswordResponse {
  token: string;
  message: string;
}

export interface UploadUrlResponse {
  url: string;
  key: string;
}

export interface VoteResponse {
  confidence: number;
  status: PostStatus;
  tallies: Tallies;
}

export interface FeedResponse {
  posts: Post[];
}

