import { Schema, model, Types, type Model } from 'mongoose';

export const REPUTATION_REASONS = ['confirmed-drop', 'vote-cast', 'phantom-post'] as const;
export type ReputationReason = (typeof REPUTATION_REASONS)[number];

export interface IReputationEvent {
    user: Types.ObjectId;
    delta: number;
    reason: ReputationReason;
    post?: Types.ObjectId;
    createdAt: Date;
}

type ReputationEventModel = Model<IReputationEvent>;

const reputationEventSchema = new Schema<IReputationEvent, ReputationEventModel>({
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    delta: { type: Number, required: true },
    reason: { type: String, enum: [...REPUTATION_REASONS], required: true },
    post: { type: Schema.Types.ObjectId, ref: 'Post' },
    createdAt: { type: Date, default: Date.now },
});

reputationEventSchema.index({ createdAt: -1 });

export const ReputationEvent = model<IReputationEvent, ReputationEventModel>('ReputationEvent', reputationEventSchema);
