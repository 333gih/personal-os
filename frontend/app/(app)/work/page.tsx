"use client";

import { DomainPage } from "@/features/domain/domain-page";
import { WorkMobile } from "@/features/work/work-mobile";

export default function WorkPage() {
  return (
    <>
      <div className="lg:hidden">
        <WorkMobile />
      </div>
      <div className="hidden lg:block">
        <DomainPage domain="work" />
      </div>
    </>
  );
}
