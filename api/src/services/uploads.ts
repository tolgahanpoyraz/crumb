import crypto from 'crypto';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import config from '../config/env.js';
import { AppError } from '../errors.js';

const s3 = new S3Client({ region: config.awsRegion });

export async function createUploadUrl() {
    if (!config.s3Bucket) {
        throw new AppError(503, 'Image uploads are not configured');
    }

    const key = `posts/${crypto.randomUUID()}.jpg`;
    const url = await getSignedUrl(
        s3,
        new PutObjectCommand({ Bucket: config.s3Bucket, Key: key, ContentType: 'image/jpeg' }),
        { expiresIn: 120 },
    );

    return { url, key };
}

export async function createAvatarUploadUrl(userId: string) {
    if (!config.s3Bucket) {
        throw new AppError(503, 'Image uploads are not configured');
    }

    const key = `avatars/${userId}.jpg`;
    const url = await getSignedUrl(
        s3,
        new PutObjectCommand({ Bucket: config.s3Bucket, Key: key, ContentType: 'image/jpeg' }),
        { expiresIn: 120 },
    );

    return { url, key };
}
