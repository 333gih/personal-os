"use client";

import { Suspense, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { getAccessToken } from "@/lib/auth/access-token";
import type { AuthMode } from "@/lib/auth/channels";
import { GoogleSignInButton } from "@/components/auth/google-sign-in-button";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

type CommercialStep = "sign-in" | "otp-request" | "otp-verify";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [mode, setMode] = useState<AuthMode>("commercial");
  const [commercialStep, setCommercialStep] = useState<CommercialStep>("sign-in");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [otp, setOtp] = useState("");
  const [remember, setRemember] = useState(false);
  const [error, setError] = useState("");
  const [info, setInfo] = useState("");
  const [loading, setLoading] = useState(false);

  const goNext = async () => {
    await getAccessToken(true);
    const next = searchParams.get("next");
    router.push(next && next.startsWith("/") ? next : "/dashboard");
  };

  const handlePasswordLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setInfo("");
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ email, password, remember_me: remember, mode }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg =
          (typeof body.error === "string" && body.error) ||
          (typeof body.message === "string" && body.message) ||
          "Login failed";
        setError(res.status > 0 ? `[${res.status}] ${msg}` : msg);
        return;
      }
      await goNext();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  };

  const handleGoogleCredential = async (credential: string) => {
    setLoading(true);
    setError("");
    setInfo("");
    try {
      const res = await fetch("/api/auth/social-login", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({
          provider: "google",
          provider_token: credential,
          remember_me: remember,
          mode: "commercial",
        }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg =
          (typeof body.error === "string" && body.error) ||
          (typeof body.message === "string" && body.message) ||
          "Google sign-in failed";
        setError(msg);
        return;
      }
      if (body.is_new_user) {
        setInfo("Welcome! Your Fash account was created and synced.");
      }
      await goNext();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Google sign-in failed");
    } finally {
      setLoading(false);
    }
  };

  const handleOtpRequest = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setInfo("");
    try {
      const res = await fetch("/api/auth/otp/request", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ email }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg =
          (typeof body.error === "string" && body.error) ||
          (typeof body.message === "string" && body.message) ||
          "Could not send verification code";
        setError(msg);
        return;
      }
      setCommercialStep("otp-verify");
      setInfo(
        body.is_new_user
          ? "We sent a code to your email. After verification, your Fash account will be created."
          : "We sent a verification code to your email.",
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not send verification code");
    } finally {
      setLoading(false);
    }
  };

  const handleOtpVerify = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/auth/otp/verify", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ email, otp, remember_me: remember }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        const msg =
          (typeof body.error === "string" && body.error) ||
          (typeof body.message === "string" && body.message) ||
          "Verification failed";
        setError(msg);
        return;
      }
      if (body.is_new_user) {
        setInfo("Account created and synced with Fash apps.");
      }
      await goNext();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Verification failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Card className="w-full max-w-md">
      <CardHeader className="text-center">
        <CardTitle className="text-2xl">Personal OS</CardTitle>
        <CardDescription>
          {mode === "internal"
            ? "Internal staff access (admin required)"
            : "Commercial access — same Fash account as mobile apps"}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-2 rounded-lg bg-muted p-1">
          <button
            type="button"
            className={`rounded-md px-3 py-2 text-sm font-medium transition-colors ${
              mode === "commercial" ? "bg-background shadow-sm" : "text-muted-foreground"
            }`}
            onClick={() => {
              setMode("commercial");
              setCommercialStep("sign-in");
              setError("");
              setInfo("");
            }}
          >
            Commercial
          </button>
          <button
            type="button"
            className={`rounded-md px-3 py-2 text-sm font-medium transition-colors ${
              mode === "internal" ? "bg-background shadow-sm" : "text-muted-foreground"
            }`}
            onClick={() => {
              setMode("internal");
              setError("");
              setInfo("");
            }}
          >
            Internal
          </button>
        </div>

        {mode === "internal" ? (
          <form onSubmit={handlePasswordLogin} className="space-y-4">
            <div>
              <label className="text-sm font-medium">Email</label>
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>
            <div>
              <label className="text-sm font-medium">Password</label>
              <Input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                autoComplete="current-password"
              />
            </div>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={remember}
                onChange={(e) => setRemember(e.target.checked)}
              />
              Remember me
            </label>
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? "Signing in..." : "Sign In (Internal)"}
            </Button>
          </form>
        ) : commercialStep === "sign-in" ? (
          <div className="space-y-4">
            <GoogleSignInButton disabled={loading} onCredential={handleGoogleCredential} />
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <span className="w-full border-t" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-card px-2 text-muted-foreground">or email</span>
              </div>
            </div>
            <form onSubmit={handlePasswordLogin} className="space-y-4">
              <div>
                <label className="text-sm font-medium">Email</label>
                <Input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  autoComplete="email"
                />
              </div>
              <div>
                <label className="text-sm font-medium">Password</label>
                <Input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  autoComplete="current-password"
                />
              </div>
              <label className="flex items-center gap-2 text-sm">
                <input
                  type="checkbox"
                  checked={remember}
                  onChange={(e) => setRemember(e.target.checked)}
                />
                Remember me
              </label>
              {error && <p className="text-sm text-destructive">{error}</p>}
              {info && <p className="text-sm text-muted-foreground">{info}</p>}
              <Button type="submit" className="w-full" disabled={loading}>
                {loading ? "Signing in..." : "Sign In"}
              </Button>
            </form>
            <Button
              type="button"
              variant="ghost"
              className="w-full"
              onClick={() => {
                setCommercialStep("otp-request");
                setError("");
                setInfo("");
              }}
            >
              Sign up or sign in with email code
            </Button>
          </div>
        ) : commercialStep === "otp-request" ? (
          <form onSubmit={handleOtpRequest} className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Enter your email to receive a one-time code. New accounts sync to Fash iOS/Android.
            </p>
            <div>
              <label className="text-sm font-medium">Email</label>
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? "Sending..." : "Send verification code"}
            </Button>
            <Button
              type="button"
              variant="ghost"
              className="w-full"
              onClick={() => setCommercialStep("sign-in")}
            >
              Back
            </Button>
          </form>
        ) : (
          <form onSubmit={handleOtpVerify} className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Enter the code sent to <strong>{email}</strong>
            </p>
            <div>
              <label className="text-sm font-medium">Verification code</label>
              <Input
                value={otp}
                onChange={(e) => setOtp(e.target.value)}
                required
                inputMode="numeric"
                autoComplete="one-time-code"
              />
            </div>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={remember}
                onChange={(e) => setRemember(e.target.checked)}
              />
              Remember me
            </label>
            {error && <p className="text-sm text-destructive">{error}</p>}
            {info && <p className="text-sm text-muted-foreground">{info}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? "Verifying..." : "Verify & continue"}
            </Button>
            <Button
              type="button"
              variant="ghost"
              className="w-full"
              onClick={() => setCommercialStep("otp-request")}
            >
              Resend code
            </Button>
          </form>
        )}

        <p className="text-center text-xs text-muted-foreground">
          Login channel:{" "}
          <code>{mode === "internal" ? "personal_os_web_internal" : "personal_os_web_commercial"}</code>
        </p>
      </CardContent>
    </Card>
  );
}

export default function LoginPage() {
  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-muted/30 p-4">
      <Suspense fallback={<p className="text-sm text-muted-foreground">Loading...</p>}>
        <LoginForm />
      </Suspense>
    </div>
  );
}
