import { Schema, model, Types, type Model } from 'mongoose';
import { VOTE_TYPES, type VoteType } from './Post.js';

export interface IVote {
    post: Types.ObjectId;
    user: Types.ObjectId;
    type: VoteType;
    expiresAt: Date;
}

type VoteModel = Model<IVote>;

const voteSchema = new Schema<IVote, VoteModel>(
    {
        post: { type: Schema.Types.ObjectId, ref: 'Post', required: true },
        user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        type: { type: String, enum: [...VOTE_TYPES], required: true },
        expiresAt: { type: Date, required: true },
    },
    { timestamps: true },
);

voteSchema.index({ post: 1, user: 1 }, { unique: true });
voteSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

export const Vote = model<IVote, VoteModel>('Vote', voteSchema);
