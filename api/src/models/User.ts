import { Schema, model, type Model } from 'mongoose';
import bcrypt from 'bcrypt';

export interface IUser {
    email: string,
    password: string,
    verified?: boolean,
    verificationToken?: string,
    verificationTokenExpires?: Date,
    resetToken?: string,
    resetTokenExpires?: Date,
    passwordChangedAt?: Date,
}

interface IUserMethods {
    comparePassword(candidate: string): Promise<boolean>;
    passwordChangedAfter(tokenIssuedAtSeconds: number): boolean;
}

type UserModel = Model<IUser, {}, IUserMethods>;

const userSchema = new Schema<IUser, UserModel, IUserMethods>(
    {
        email: { type: String, required: true, unique: true, lowercase: true, trim: true },
        password: { type: String, required: true, select: false },
        verified: { type: Boolean, default: false },
        verificationToken: { type: String, select: false },
        verificationTokenExpires: { type: Date, select: false },
        resetToken: { type: String, select: false },
        resetTokenExpires: { type: Date, select: false },
        passwordChangedAt: { type: Date, select: false },
    }
)

userSchema.pre('save', async function () {
    if (!this.isModified('password')) {
        return;
    }
    this.password = await bcrypt.hash(this.password, 12);
    this.passwordChangedAt = new Date(Date.now() - 1000);
});

userSchema.methods.comparePassword = async function (candidate: string) {
    return bcrypt.compare(candidate, this.password);
};

userSchema.methods.passwordChangedAfter = function (tokenIssuedAtSeconds: number): boolean {
    if (!this.passwordChangedAt) {
        return false;
    }
    const changedAtSeconds = Math.floor(this.passwordChangedAt.getTime() / 1000);
    return changedAtSeconds > tokenIssuedAtSeconds;
};

export const User = model<IUser, UserModel>('User', userSchema);

