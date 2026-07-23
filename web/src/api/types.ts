// Types mirroring api/openapi.yaml. Kept in sync by hand.

export type PostStatus = 'fresh' | 'likely' | 'fading' | 'gone';

export type PostType = 'pizza' | 'meal' | 'snacks' | 'baked-goods' | 'drinks' | 'other';

export type DietaryTag = 'vegetarian' | 'vegan' | 'halal' | 'kosher' | 'gluten-free';

export type VoteType = 'present' | 'gone';

export type Tier = 0 | 1 | 2 | 3;

export interface User {
  id: string;
  displayName: string;
  email: string;
  avatarKey?: string;
  verified?: boolean;
  reputation?: number;
  tier?: Tier;
  nextTierAt?: number | null;
}

export interface CampusLocation {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
}

export interface Tallies {
  present: number;
  gone: number;
}

export interface Post {
  _id: string;
  foodName: string;
  type: PostType;
  dietaryTags: DietaryTag[];
  location: CampusLocation;
  locationDetail?: string;
  imageKey?: string;
  author: string;
  authorName?: string;
  authorAvatarKey?: string;
  authorTier?: Tier;
  status: PostStatus;
  confidence: number;
  tallies: Tallies;
  expiresAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}

export interface MeResponse {
  user: User;
}

export interface ChangePasswordResponse {
  token: string;
  message: string;
}

export interface MessageResponse {
  message: string;
}

export interface FeedResponse {
  posts: Post[];
}

export interface CreatePostRequest {
  foodName: string;
  type: PostType;
  dietaryTags?: DietaryTag[];
  location: string;
  locationDetail?: string;
  imageKey?: string;
}

export interface CreatePostResponse {
  post: Post;
}

export interface VoteResponse {
  confidence: number;
  status: PostStatus;
  tallies: Tallies;
}

export interface LocationsResponse {
  locations: CampusLocation[];
}

export interface UploadUrlResponse {
  url: string;
  key: string;
}

export interface LeaderboardEntry {
  userId: string;
  displayName: string;
  avatarKey?: string;
  weeklyPoints: number;
  tier: Tier;
  rank: number;
}

export interface LeaderboardMe {
  rank: number | null;
  weeklyPoints: number;
  reputation: number;
  tier: Tier;
}

export interface LeaderboardResponse {
  entries: LeaderboardEntry[];
  me: LeaderboardMe;
}
