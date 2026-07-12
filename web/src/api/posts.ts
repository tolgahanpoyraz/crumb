/* web/src/api/posts.ts */

import { apiRequest } from './apiClient.js';
import type {
  FeedResponse,
  Post,
  PostLocation,
  PostType,
  DietaryTag,
  UploadUrlResponse,
  VoteResponse,
} from './types.js';

// Shape the backend actually sends over the wire.
interface RawPost {
  _id: string;
  foodName: string;
  type: PostType;
  dietaryTags: DietaryTag[];
  location: PostLocation;
  locationDetail?: string;
  imageKey?: string;
  author: string;
  status: Post['status'];
  confidence?: number;
  tallies: Post['tallies'];
  expiresAt: string;
  createdAt: string;
}

// Converts a raw backend post into the shape the rest of the app expects.
function normalizePost(raw: RawPost): Post {
  return {
    id: raw._id,
    foodName: raw.foodName,
    type: raw.type,
    dietaryTags: raw.dietaryTags,
    location: raw.location,
    locationDetail: raw.locationDetail,
    imageKey: raw.imageKey,
    author: raw.author,
    status: raw.status,
    confidence: raw.confidence,
    tallies: raw.tallies,
    expiresAt: raw.expiresAt,
    createdAt: raw.createdAt,
  };
}

export const postService = {
  /**
   * Fetch active posts from the feed (public endpoint).
   */
  async getFeed(): Promise<FeedResponse> {
    const data = await apiRequest<{ posts: RawPost[] }>('/posts', {
      method: 'GET',
    });
    return { posts: data.posts.map(normalizePost) };
  },

  /**
   * Create a new food post (requires auth).
   */
  async createPost(body: {
    foodName: string;
    type: PostType;
    dietaryTags?: DietaryTag[];
    location: string;
    locationDetail?: string;
    imageKey?: string;
  }): Promise<{ post: Post }> {
    const data = await apiRequest<{ post: RawPost }>('/posts', {
      method: 'POST',
      bodyData: body,
    });
    return { post: normalizePost(data.post) };
  },

  /**
   * Request a short-lived presigned S3 PUT URL for image uploading (requires auth).
   */
  async getUploadUrl(): Promise<UploadUrlResponse> {
    return apiRequest<UploadUrlResponse>('/posts/upload-url', {
      method: 'GET',
    });
  },

  /**
   * Vote "present" (still here) or "gone" (not there anymore) on a post (requires auth).
   */
  async votePost(id: string, type: 'present' | 'gone'): Promise<VoteResponse> {
    return apiRequest<VoteResponse>(`/posts/${id}/vote`, {
      method: 'POST',
      bodyData: { type },
    });
  },

  /**
   * Delete a post the current user authored (requires auth).
   */
  async deletePost(id: string): Promise<void> {
    await apiRequest<void>(`/posts/${id}`, {
      method: 'DELETE',
    });
  },

  /**
   * Upload binary data directly to an S3 presigned URL using PUT.
   * This bypasses the Express backend.
   */
  async uploadImageToS3(url: string, file: File): Promise<void> {
    const response = await fetch(url, {
      method: 'PUT',
      headers: {
        'Content-Type': file.type,
      },
      body: file,
    });

    if (!response.ok) {
      throw new Error(`S3 upload failed with status ${response.status}`);
    }
  },
};