import { request, putImage } from './client';
import type {
  CreatePostRequest,
  CreatePostResponse,
  FeedResponse,
  UploadUrlResponse,
  VoteResponse,
  VoteType,
} from './types';

export function getFeed(signal?: AbortSignal) {
  return request<FeedResponse>('/posts', { signal });
}

export function createPost(data: CreatePostRequest) {
  return request<CreatePostResponse>('/posts', { method: 'POST', auth: true, body: data });
}

export function vote(postId: string, type: VoteType) {
  return request<VoteResponse>(`/posts/${postId}/vote`, {
    method: 'POST',
    auth: true,
    body: { type },
  });
}

export function deletePost(postId: string) {
  return request<void>(`/posts/${postId}`, { method: 'DELETE', auth: true });
}

// Presigned upload for a post photo: returns the object key to attach to the post.
export async function uploadPostImage(file: Blob): Promise<string> {
  const { url, key } = await request<UploadUrlResponse>('/posts/upload-url', { auth: true });
  await putImage(url, file);
  return key;
}
