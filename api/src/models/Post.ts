import { Schema, model, Types, type Model } from 'mongoose';
import { E_INITIAL } from '../confidence.js';

export type VoteType = 'present' | 'gone';
export type PostStatus = 'fresh' | 'likely' | 'fading' | 'gone';

export interface IVote {
    user: Types.ObjectId;
    type: VoteType;
    at: Date;
}

export interface IPost {
    foodName: string;
    location: string;
    imageKey?: string;
    badges: string[];
    author: Types.ObjectId;
    E: number;
    lastUpdate: Date;
    expiresAt: Date;
    tallies: { present: number; gone: number };
    status: PostStatus;
    votes: IVote[];
}

type PostModel = Model<IPost>;

const voteSchema = new Schema<IVote>(
    {
        user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        type: { type: String, enum: ['present', 'gone'], required: true },
        at: { type: Date, default: Date.now },
    },
    { _id: false },
);

const postSchema = new Schema<IPost, PostModel>(
    {
        foodName: { type: String, required: true, trim: true },
        location: { type: String, required: true, trim: true },
        imageKey: { type: String },
        badges: { type: [String], default: [] },
        author: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        E: { type: Number, default: E_INITIAL },
        lastUpdate: { type: Date, default: Date.now },
        expiresAt: { type: Date },
        tallies: {
            present: { type: Number, default: 0 },
            gone: { type: Number, default: 0 },
        },
        status: { type: String, enum: ['fresh', 'likely', 'fading', 'gone'], default: 'fresh' },
        votes: { type: [voteSchema], default: [], select: false },
    },
    { timestamps: true },
);

postSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const Post = model<IPost, PostModel>('Post', postSchema);