module Job
  class ReportScheduleProblems < Base
    @priority = :low

    class << self
      def perform
        gaps     = ScheduleOccurrence.gaps
        overlaps = ScheduleOccurrence.overlaps

        logger.info("Gaps have been spotted in the program schedule.") if gaps.any? 
        logger.info("Overlapping has been spotted in the program schedule.") if overlaps.any? 

        ReportScheduleProblemsMailer.send_notification(gaps, overlaps).deliver_now
        nil
      end
    end
  end
end
