import { redirect } from 'next/navigation';

export default function SettingsNotificationsDeepLinkPage() {
  redirect('/open?path=%2Fsettings%2Fnotifications');
}
