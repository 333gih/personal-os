"use client";

import { DomainPage } from "@/features/domain/domain-page";
import { LearningMobile } from "@/features/learning/learning-mobile";

export default function LearningPage() {
  return (
    <>
      <div className="lg:hidden">
        <LearningMobile />
      </div>
      <div className="hidden lg:block">
        <DomainPage domain="learning" />
      </div>
    </>
  );
}
