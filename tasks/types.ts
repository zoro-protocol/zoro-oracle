export interface AddressConfig {
  [contract: string]: { [chainId: number]: string };
}

export interface ConfigureFeedParams {
  feedId: string;
}

export interface SetCTokenFeedParams {
  cToken: string;
  asset: string;
}

export interface Feed {
  feed: string;
  decimals: number;
  underlyingDecimals: number;
}

export interface FeedDataConfig {
  [name: string]: Feed;
}
