'use client';

import { FormEvent, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { PageHeader } from '@/components/page-header';
import { useAdminSession } from '@/components/admin-shell';
import { EmailPreview } from './EmailPreview';
import { PushPreview } from './PushPreview';
import { PushForm } from './PushForm';
import { EmailForm } from './EmailForm';
import { EmailConfirmDialog } from './EmailConfirmDialog';
import { PushConfirmDialog } from './PushConfirmDialog';
import {
  BroadcastErrorCard,
  EmailResultCard,
  PushResultCard,
} from './NotificationResultCards';
import {
  TARGET_OPTIONS,
  usePushBroadcast,
} from '../_hooks/use-push-broadcast';
import { useEmailBroadcast } from '../_hooks/use-email-broadcast';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

type NotificationsTab = 'push' | 'email';

function asSubmitEvent(): FormEvent {
  return new Event('submit') as unknown as FormEvent;
}

export default function NotificationsPageClient() {
  const session = useAdminSession();
  const canSend = session.effectiveRoles.some(
    (role) => role === 'admin' || role === 'owner',
  );
  const [activeTab, setActiveTab] = useState<NotificationsTab>('push');

  const push = usePushBroadcast(canSend);
  const email = useEmailBroadcast(canSend);

  return (
    <div className='space-y-6'>
      <PageHeader
        title='Notifications'
        description='Send push/in-app notifications and email broadcasts from dedicated tabs.'
      />

      {!canSend && (
        <Card className='border-amber-500/30 bg-amber-500/5'>
          <CardContent className='pt-6 text-sm text-amber-200'>
            Sending notifications requires admin or owner role.
          </CardContent>
        </Card>
      )}

      <Tabs
        value={activeTab}
        onValueChange={(value) => setActiveTab(value as NotificationsTab)}
        className='space-y-4'>
        <TabsList className='grid w-full max-w-[420px] grid-cols-2'>
          <TabsTrigger value='push'>Push (In-App)</TabsTrigger>
          <TabsTrigger value='email'>Email Broadcast</TabsTrigger>
        </TabsList>

        <TabsContent value='push' className='space-y-4'>
          {push.result && <PushResultCard result={push.result} />}
          {push.error && <BroadcastErrorCard error={push.error} />}

          <div className='grid gap-6 lg:grid-cols-3'>
            <div className='lg:col-span-2'>
              <Card>
                <CardHeader>
                  <CardTitle className='text-base'>
                    Push + In-app Broadcast
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  <PushForm
                    canSend={canSend}
                    title={push.title}
                    body={push.body}
                    target={push.target}
                    targetOptions={TARGET_OPTIONS}
                    onChangeTitle={push.setTitle}
                    onChangeBody={push.setBody}
                    onChangeTarget={push.setTarget}
                    selectedUsers={push.selectedUsers}
                    searchQuery={push.searchQuery}
                    setSearchQuery={(value) => {
                      push.setSearchQuery(value);
                      push.resetSearch();
                    }}
                    searching={push.searching}
                    searched={push.searched}
                    searchResults={push.searchResults}
                    onSearch={() => void push.handleSearch()}
                    onAddUser={push.addUser}
                    onRemoveUser={push.removeUser}
                    onSubmit={() => push.handleSubmit(asSubmitEvent())}
                  />
                </CardContent>
              </Card>
            </div>

            <div>
              <PushPreview
                title={push.title}
                body={push.body}
                audienceLabel={push.selectedTargetOption.label}
                isSpecific={push.target === 'specific'}
                recipientsCount={push.selectedUsers.length}
              />
            </div>
          </div>
        </TabsContent>

        <TabsContent value='email' className='space-y-4'>
          {email.emailResult && <EmailResultCard result={email.emailResult} />}
          {email.emailError && <BroadcastErrorCard error={email.emailError} />}

          <div className='grid gap-6 lg:grid-cols-3'>
            <div className='lg:col-span-2'>
              <Card>
                <CardHeader>
                  <CardTitle className='text-base'>Email Broadcast</CardTitle>
                </CardHeader>
                <CardContent>
                  <EmailForm
                    canSend={canSend}
                    emailStatus={
                      email.emailStatus
                        ? {
                            configured: email.emailStatus.configured,
                            reason: email.emailStatus.reason,
                            allowedFromAddresses:
                              email.emailStatus.allowedFromAddresses,
                          }
                        : null
                    }
                    fromAddress={email.emailFromAddress}
                    fromName={email.emailFromName}
                    replyTo={email.emailReplyTo}
                    subject={email.emailSubject}
                    previewText={email.emailPreviewText}
                    message={email.emailMessage}
                    ctaLabel={email.emailCtaLabel}
                    ctaUrl={email.emailCtaUrl}
                    target={email.emailTarget}
                    targetOptions={TARGET_OPTIONS}
                    onChangeFromAddress={email.setEmailFromAddress}
                    onChangeFromName={email.setEmailFromName}
                    onChangeReplyTo={email.setEmailReplyTo}
                    onChangeSubject={email.setEmailSubject}
                    onChangePreviewText={email.setEmailPreviewText}
                    onChangeMessage={email.setEmailMessage}
                    onChangeCtaLabel={email.setEmailCtaLabel}
                    onChangeCtaUrl={email.setEmailCtaUrl}
                    onChangeTarget={email.setEmailTarget}
                    selectedUsers={email.emailSelectedUsers}
                    searchQuery={email.emailSearchQuery}
                    setSearchQuery={(value) => {
                      email.setEmailSearchQuery(value);
                      email.resetSearch();
                    }}
                    searching={email.emailSearching}
                    searched={email.emailSearched}
                    searchResults={email.emailSearchResults}
                    onSearch={() => void email.handleEmailSearch()}
                    onAddUser={email.addEmailUser}
                    onRemoveUser={email.removeEmailUser}
                    onSubmit={() => email.handleEmailSubmit(asSubmitEvent())}
                  />
                </CardContent>
              </Card>
            </div>

            <div>
              <EmailPreview
                fromAddress={email.emailFromAddress}
                fromName={email.emailFromName}
                subject={email.emailSubject}
                message={email.emailMessage}
                audienceLabel={email.selectedEmailTargetOption.label}
                isSpecific={email.emailTarget === 'specific'}
                recipientsCount={email.emailSelectedUsers.length}
                ratePerMinute={email.emailStatus?.broadcastRatePerMinute ?? null}
              />
            </div>
          </div>
        </TabsContent>
      </Tabs>

      <PushConfirmDialog
        open={push.confirmOpen}
        onOpenChange={push.setConfirmOpen}
        sending={push.sending}
        title={push.title}
        body={push.body}
        targetLabel={push.selectedTargetOption.label}
        isSpecific={push.target === 'specific'}
        selectedUsersCount={push.selectedUsers.length}
        onConfirm={push.confirmSend}
      />

      <EmailConfirmDialog
        open={email.emailConfirmOpen}
        onOpenChange={email.setEmailConfirmOpen}
        sending={email.emailSending}
        subject={email.emailSubject}
        message={email.emailMessage}
        targetLabel={email.selectedEmailTargetOption.label}
        isSpecific={email.emailTarget === 'specific'}
        selectedUsersCount={email.emailSelectedUsers.length}
        onConfirm={email.confirmEmailSend}
      />
    </div>
  );
}
