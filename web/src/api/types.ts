/* web/src/api/types.ts */

export interface User {
  id: string;
  displayName: string;
  email: string;
  avatarKey?: string;
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

export type PostType = 'pizza' | 'meal' | 'snacks' | 'baked-goods' | 'drinks' | 'other';

export const POST_TYPES: PostType[] = ['pizza', 'meal', 'snacks', 'baked-goods', 'drinks', 'other'];

export type DietaryTag = 'vegetarian' | 'vegan' | 'halal' | 'kosher' | 'gluten-free';

export const DIETARY_TAGS: DietaryTag[] = ['vegetarian', 'vegan', 'halal', 'kosher', 'gluten-free'];

export interface Tallies {
  present: number;
  gone: number;
}

// Matches the CampusLocation 
export interface PostLocation {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
}

export interface Post {
  id: string;
  foodName: string;
  type: PostType;
  dietaryTags: DietaryTag[];
  location: PostLocation;
  locationDetail?: string;
  imageKey?: string;
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