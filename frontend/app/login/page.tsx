"use client";

import { Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { getAccessToken } from "@/lib/auth/access-token";
import { buildAdminPortalInternalLoginUrl } from "@/lib/auth/admin-portal-sso";
import { GoogleSignInButton } from "@/components/auth/google-sign-in-button";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

type CommercialStep = "sign-in" | "otp-request" | "otp-verify";
type AuthMode = "internal" | "commercial";

const DEFAULT_INTERNAL_LOGIN_ENABLED =
  process.env.NEXT_PUBLIC_INTERNAL_DEFAULT_LOGIN_ENABLED === "true" ||
  process.env.NODE_ENV === "development";

const SSO_ERROR_MESSAGES: Record<string, string> = {
  missing_ticket: "Admin Portal did not return a session ticket.",
  invalid_ticket: "Session ticket expired or invalid. Please sign in again.",
  not_admin: "Your Admin Portal account is not authorized for Personal OS internal access.",
  sso_not_configured: "Internal SSO is not configured on this deployment.",
  callback_failed: "Could not complete Admin Portal sign-in.",
};

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

  useEffect(() => {
    const code = searchParams.get("error");
    if (code && SSO_ERROR_MESSAGES[code]) {
      setError(SSO_ERROR_MESSAGES[code] ?? "");
      setMode("internal");
    }
  }, [searchParams]);

  const safeNext = (): string => {
    const next = searchParams.get("next");
    return next && next.startsWith("/") ? next : "/dashboard";
  };

  const goNext = async () => {
    await getAccessToken(true);
    router.push(safeNext());
  };

  const handleAdminPortalRedirect = () => {
    setError("");
    window.location.href = buildAdminPortalInternalLoginUrl(safeNext());
  };

  const handleDefaultInternalLogin = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/auth/internal/default-login", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ remember_me: remember }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(
          (typeof body.error === "string" && body.error) ||
            (typeof body.message === "string" && body.message) ||
            "Default login failed",
        );
        return;
      }
      await goNext();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Default login failed");
    } finally {
      setLoading(false);
    }
  };

  const handleCommercialPasswordLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setInfo("");
    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ email, password, remember_me: remember }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(
          (typeof body.error === "string" && body.error) ||
            (typeof body.message === "string" && body.message) ||
            "Login failed",
        );
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
        setError(
          (typeof body.error === "string" && body.error) ||
            (typeof body.message === "string" && body.message) ||
            "Google sign-in failed",
        );
        return;
      }
      if (body.is_new_user) setInfo("Welcome! Your Fash account was created and synced.");
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
    try {
      const res = await fetch("/api/auth/otp/request", {
        method: "POST",
        credentials: "same-origin",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ email }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(
          (typeof body.error === "string" && body.error) ||
            (typeof body.message === "string" && body.message) ||
            "Could not send verification code",
        );
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
        setError(
          (typeof body.error === "string" && body.error) ||
            (typeof body.message === "string" && body.message) ||
            "Verification failed",
        );
        return;
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
            ? "Internal — sign in via Fash Admin Portal"
            : "Commercial — same Fash account as mobile apps"}
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-2 gap-2 rounded-lg bg-muted p-1">
          <button
            type="button"
            className={`min-h-11 rounded-md px-3 text-sm font-medium transition-colors active:scale-[0.98] ${
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
            className={`min-h-11 rounded-md px-3 text-sm font-medium transition-colors active:scale-[0.98] ${
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
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Internal access uses your Admin Portal session. You will be redirected to Fash Admin
              Portal to sign in; after success, your session is passed back here automatically.
            </p>
            <Button type="button" className="w-full" disabled={loading} onClick={handleAdminPortalRedirect}>
              Continue to Admin Portal
            </Button>
            {error && <p className="text-sm text-destructive">{error}</p>}
            {DEFAULT_INTERNAL_LOGIN_ENABLED ? (
              <>
                <div className="relative">
                  <div className="absolute inset-0 flex items-center">
                    <span className="w-full border-t" />
                  </div>
                  <div className="relative flex justify-center text-xs uppercase">
                    <span className="bg-card px-2 text-muted-foreground">dev only</span>
                  </div>
                </div>
                <Button
                  type="button"
                  variant="outline"
                  className="w-full"
                  disabled={loading}
                  onClick={() => void handleDefaultInternalLogin()}
                >
                  Default internal account
                </Button>
              </>
            ) : null}
          </div>
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
            <form onSubmit={handleCommercialPasswordLogin} className="space-y-4">
              <div>
                <label className="text-sm font-medium">Email</label>
                <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
              </div>
              <div>
                <label className="text-sm font-medium">Password</label>
                <Input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                />
              </div>
              <label className="flex items-center gap-2 text-sm">
                <input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} />
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
              }}
            >
              Sign up or sign in with email code
            </Button>
          </div>
        ) : commercialStep === "otp-request" ? (
          <form onSubmit={handleOtpRequest} className="space-y-4">
            <div>
              <label className="text-sm font-medium">Email</label>
              <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
            </div>
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              Send verification code
            </Button>
            <Button type="button" variant="ghost" className="w-full" onClick={() => setCommercialStep("sign-in")}>
              Back
            </Button>
          </form>
        ) : (
          <form onSubmit={handleOtpVerify} className="space-y-4">
            <div>
              <label className="text-sm font-medium">Verification code</label>
              <Input value={otp} onChange={(e) => setOtp(e.target.value)} required inputMode="numeric" />
            </div>
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              Verify & continue
            </Button>
          </form>
        )}

        <p className="text-center text-xs text-muted-foreground">
          Channel:{" "}
          <code>{mode === "internal" ? "personal_os_web_internal" : "personal_os_web_commercial"}</code>
        </p>
      </CardContent>
    </Card>
  );
}

export default function LoginPage() {
  return (
    <div className="flex min-h-[100dvh] items-center justify-center bg-muted/30 p-4 pt-safe pb-safe">
      <Suspense fallback={<p className="text-sm text-muted-foreground">Loading...</p>}>
        <div className="w-full max-w-md">
          <LoginForm />
        </div>
      </Suspense>
    </div>
  );
}
