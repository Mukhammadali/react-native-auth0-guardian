export function initialize(auth0Domain:string): Promise<boolean>;

export function enroll(enrollmentURI:string, deviceToken: string): Promise<string>;

export function unenroll(): Promise<boolean>;

export function getTOTP(): Promise<string>

export function allow(notificationData: { [key:string]:string }): Promise<boolean>

export function reject(notificationData: { [key:string]:string }): Promise<boolean>
declare namespace Auth0Guardian {
}

export default Auth0Guardian
