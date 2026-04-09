import { IsIn, IsString } from 'class-validator';

const ALLOWED_CHANNEL_EMOJIS = ['👍', '❤️', '🔥', '👏', '😮'] as const;

export class ReactChannelPostDto {
  @IsString()
  @IsIn(ALLOWED_CHANNEL_EMOJIS as unknown as string[])
  emoji!: (typeof ALLOWED_CHANNEL_EMOJIS)[number];
}
