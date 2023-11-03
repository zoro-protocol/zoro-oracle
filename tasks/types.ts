export interface AddressConfig {
  [contract: string]: { [chainId: number]: string };
}

export interface SetFeedDataParams {
  asset: string;
}

export interface SetCTokenFeedParams {
  cToken: string;
  asset: string;
}

export interface FeedData {
  feed: string;
  decimals: number;
  underlyingDecimals: number;
}

export interface FeedDataConfig {
  [name: string]: FeedData;
}
