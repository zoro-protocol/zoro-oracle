export interface ConfigureFeedParams {
  feedId: string;
}

export interface ConnectCTokenToFeedParams {
  cTokenId: string;
  feedId: string;
}

export interface Feed {
  feed: string;
  decimals: number;
  underlyingDecimals: number;
}

export interface FeedDataConfig {
  [name: string]: Feed;
}

export type OracleConstructorArgs = [string, string, string];
