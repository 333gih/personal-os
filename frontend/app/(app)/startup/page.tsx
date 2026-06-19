"use client";

import { DomainPage } from "@/features/domain/domain-page";
import { StartupMobile } from "@/features/startup/startup-mobile";

export default function StartupPage() {
  return (
    <>
      <div className="lg:hidden">
        <StartupMobile />
      </div>
      <div className="hidden lg:block">
        <DomainPage domain="startup" />
      </div>
    </>
  );
}
