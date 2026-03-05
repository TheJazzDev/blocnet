import { redirect } from 'next/navigation';

export default function NotificationsDeepLinkPage() {
  redirect('/open?path=%2Fnotifications');
}
