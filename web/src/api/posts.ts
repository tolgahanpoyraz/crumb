/* web/src/api/posts.ts */

import { apiRequest } from './apiClient.js';
import type { 
  FeedResponse, 
  Post, 
  UploadUrlResponse, 
  VoteResponse 
} from './types.js';

export const postService = {
  /**
   * Fetch active posts from the feed (public endpoint).
   */
  async getFeed(): Promise<FeedResponse> {
    return apiRequest<FeedResponse>('/posts', {
      method: 'GET',
    });
  },

  /**
   * Create a new food post (requires auth).
   */
  async createPost(body: { 
    foodName: string; 
    location: string; 
    badges?: string[]; 
    imageKey?: string; 
  }): Promise<{ post: Post }> {
    return apiRequest<{ post: Post }>('/posts', {
      method: 'POST',
      bodyData: body,
    });
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
