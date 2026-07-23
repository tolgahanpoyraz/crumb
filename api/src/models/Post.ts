import { Schema, model, Types, type Model } from 'mongoose';
import { E_INITIAL } from '../confidence.js';

export const VOTE_TYPES = ['present', 'gone'] as const;
export type VoteType = (typeof VOTE_TYPES)[number];

export const POST_STATUSES = ['fresh', 'likely', 'fading', 'gone'] as const;
export type PostStatus = (typeof POST_STATUSES)[number];

export const POST_TYPES = ['pizza', 'meal', 'snacks', 'baked-goods', 'drinks', 'other'] as const;
export type PostType = (typeof POST_TYPES)[number];

export const DIETARY_TAGS = ['vegetarian', 'vegan', 'halal', 'kosher', 'gluten-free'] as const;
export type DietaryTag = (typeof DIETARY_TAGS)[number];

export interface IPost {
    foodName: string;
    type: PostType;
    dietaryTags: DietaryTag[];
    location: string;
    locationDetail?: string;
    imageKey?: string;
    author: Types.ObjectId;
    E: number;
    lastUpdate: Date;
    expiresAt: Date;
    tallies: { present: number; gone: number };
    status: PostStatus;
    authorPenalized: boolean;
}

type PostModel = Model<IPost>;

const postSchema = new Schema<IPost, PostModel>(
    {
        foodName: { type: String, required: true, trim: true },
        type: { type: String, enum: [...POST_TYPES], required: true },
        dietaryTags: { type: [String], enum: [...DIETARY_TAGS], default: [] },
        location: { type: String, required: true, trim: true },
        locationDetail: { type: String, trim: true },
        imageKey: { type: String },
        author: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        E: { type: Number, default: E_INITIAL },
        lastUpdate: { type: Date, default: Date.now },
        expiresAt: { type: Date },
        tallies: {
            present: { type: Number, default: 0 },
            gone: { type: Number, default: 0 },
        },
        status: { type: String, enum: [...POST_STATUSES], default: 'fresh' },
        authorPenalized: { type: Boolean, default: false },
    },
    { timestamps: true },
);

postSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const Post = model<IPost, PostModel>('Post', postSchema);