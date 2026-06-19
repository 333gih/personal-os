"use client";

import { useEffect, useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import {
  Bell,
  Info,
  KeyRound,
  Palette,
  Shield,
  UserCircle,
} from "lucide-react";
import Link from "next/link";
import { IosSafariExtensionCard } from "@/components/ios-safari-extension-card";
import { ListRow } from "@/components/mobile/list-row";
import { SectionHeader } from "@/components/mobile/section-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { api } from "@/services/api";

export function SettingsMobile() {
  const { data: user, refetch } = useQuery({
    queryKey: ["me"],
    queryFn: () => api.me(),
  });

  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [message, setMessage] = useState("");
  const [showProfile, setShowProfile] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    if (user) {
      setName(user.name);
      setEmail(user.email);
    }
  }, [user]);

  const updateProfile = useMutation({
    mutationFn: () => api.updateProfile({ name: name || user?.name || "", email: email || user?.email }),
    onSuccess: () => {
      setMessage("Profile updated");
      refetch();
      setShowProfile(false);
    },
  });

  const changePassword = useMutation({
    mutationFn: () => api.changePassword(currentPassword, newPassword),
    onSuccess: () => {
      setMessage("Password changed");
      setCurrentPassword("");
      setNewPassword("");
      setShowPassword(false);
    },
  });

  return (
    <div className="space-y-6 pb-4">
      {message ? <p className="rounded-2xl bg-primary/10 px-4 py-2 text-sm text-primary">{message}</p> : null}

      <div className="space-y-2">
        <ListRow
          title={user?.name || "Your account"}
          subtitle={user?.email || "Sign in to sync across devices"}
          icon={UserCircle}
          iconClassName="text-primary bg-primary/10"
          onClick={() => setShowProfile((v) => !v)}
        />
        {showProfile ? (
          <div className="space-y-3 rounded-3xl bg-card p-4 shadow-sm ring-1 ring-border/50">
            <div>
              <label className="text-sm font-medium">Name</label>
              <Input value={name} onChange={(e) => setName(e.target.value)} className="mt-1" />
            </div>
            <div>
              <label className="text-sm font-medium">Email</label>
              <Input value={email} onChange={(e) => setEmail(e.target.value)} className="mt-1" />
            </div>
            <Button onClick={() => updateProfile.mutate()} disabled={updateProfile.isPending} className="w-full">
              Save profile
            </Button>
          </div>
        ) : null}

        <ListRow
          title="Password & Security"
          subtitle="Update password and session"
          icon={KeyRound}
          onClick={() => setShowPassword((v) => !v)}
        />
        {showPassword ? (
          <div className="space-y-3 rounded-3xl bg-card p-4 shadow-sm ring-1 ring-border/50">
            <div>
              <label className="text-sm font-medium">Current password</label>
              <Input
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                className="mt-1"
              />
            </div>
            <div>
              <label className="text-sm font-medium">New password</label>
              <Input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="mt-1"
              />
            </div>
            <Button onClick={() => changePassword.mutate()} disabled={changePassword.isPending} className="w-full">
              Update password
            </Button>
          </div>
        ) : null}

        <ListRow
          title="Data & Privacy"
          subtitle="Manage your sync preferences"
          icon={Shield}
          href="/settings"
        />
      </div>

      <IosSafariExtensionCard variant="featured" />

      <div>
        <SectionHeader title="General Preferences" eyebrow="Preferences" />
        <div className="mt-3 space-y-2">
          <ListRow title="Appearance" subtitle="Auto" icon={Palette} href="/settings" />
          <ListRow title="Notifications" subtitle="Reminders and updates" icon={Bell} href="/inbox" />
          <ListRow title="About Personal OS" subtitle="Version & support" icon={Info} href="/dashboard" />
        </div>
      </div>

      <p className="text-center text-xs text-muted-foreground">
        Need desktop features?{" "}
        <Link href="/entertainment" className="font-medium text-primary underline">
          Open Entertainment
        </Link>
      </p>
    </div>
  );
}
