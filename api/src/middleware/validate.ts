import { type Request, type Response, type NextFunction } from 'express';
import { type ZodError, type ZodType } from 'zod';
import { AppError } from '../errors.js';

export function validate(schema: ZodType) {
    return (req: Request, _res: Response, next: NextFunction): void => {
        const result = schema.safeParse(req.body);
        if (!result.success) {
            throw new AppError(400, formatZodError(result.error));
        }
        req.body = result.data;
        next();
    };
}

function formatZodError(error: ZodError): string {
    return error.issues
        .map((issue) => {
            const path = issue.path.join('.');
            return path ? `${path}: ${issue.message}` : issue.message;
        })
        .join('; ');
}